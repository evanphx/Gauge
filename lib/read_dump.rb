module Rubinius
  module HeapDump

    class DumpedObject
      def initialize(decoder, id, bytes, layout, klass, ivar_ref, ivars)
        @decoder = decoder
        @id = id
        @bytes = bytes
        @layout = layout
        @ivars = ivars
        @ivar_ref = ivar_ref
        @klass = klass
      end

      attr_reader :decoder
      attr_reader :id, :bytes, :layout, :ivars, :klass, :ivar_ref

      def raw_ivar(name)
        idx = @layout.index(name)
        return nil unless idx

        return @ivars[idx]
      end

      def [](name)
        ref = raw_ivar(name)
        if ref.kind_of? Reference
          return @decoder.objects[ref.id]
        end

        return ref
      end

      def to_hash
        hsh = {}
        @layout.each_with_index do |name, idx|
          hsh[name] = @ivars[idx]
        end

        hsh
      end

      def each_ivar
        @layout.each_with_index do |name, idx|
          yield name, @ivars[idx]
        end
      end

      def direct_class_object
        @klass_object ||= @decoder.objects[@klass.id].as_module
      end

      def dump_kind_of?(cls)
        start = direct_class_object

        while start
          return true if start.object == cls.object
          start = start.superclass
        end

        return false
      end

      def class_object
        start = direct_class_object
        return start unless start.metaclass?

        start = start.superclass
        cls = @decoder.Class

        while start
          return start if start.object.dump_kind_of?(cls) and !start.metaclass?
          start = start.superclass
        end

        raise "Unable to figure out class"
      end

      def as_module
        @as_module ||= DumpedModule.new(self)
      end

      def data
        @ivars[@layout.size]
      end

      def inspect
        "#<DumpedObject id=#{@id} klass=#{@klass} #{to_hash.inspect}>"
      end

      def referers
        @referers ||= Objects.new(@decoder.find_references(@id))
      end

      def references?(other)
        @ivars.each do |i|
          return true if i.kind_of? Reference and i.id == other
        end

        if d = data and d.kind_of?(HeapDump::Decoder::Tuple)
          d.objects.each do |i|
            return true if i.kind_of? Reference and i.id == other
          end
        end

        return false
      end
    end

    class Specializer
      def initialize(obj)
        @object = obj
      end

      attr_reader :object

      def ==(obj)
        @object == obj || super
      end

      def method_missing(msg, *args)
        if @object.respond_to?(msg)
          @object.__send__(msg, *args)
        else
          super
        end
      end

      def id
        @object.id
      end
    end

    class DumpedLookupTable < Specializer
      def each
        @object["@values"].data.objects.each do |ref|
          if ref
            obj = @object.decoder.deref(ref)
            while obj
              yield obj["@key"], obj["@value"]

              obj = obj["@next"]
            end
          end
        end
      end

      include Enumerable

      def keys
        map { |k,v| k.data }
      end
    end

    class DumpedMethodTable < Specializer
      def each
        @object["@values"].data.objects.each do |ref|
          if ref
            obj = @object.decoder.deref(ref)
            while obj
              yield obj["@name"], obj["@method"], obj["@visibility"]

              obj = obj["@next"]
            end
          end
        end
      end

      include Enumerable

      def keys
        map { |k,v| k.data }
      end
    end

    class DumpedModule < Specializer
      def name
        if sym = @object["@module_name"]
          sym.data
        end
      end

      def superclass
        if obj = @object["@superclass"]
          return obj.as_module
        end

        return nil
      end

      def constant_table
        @constants ||= DumpedLookupTable.new(@object["@constants"])
      end

      def constants
        constant_table.map do |key, val|
          key.data
        end
      end

      def method_table
        @methods ||= DumpedMethodTable.new(@object["@method_table"])
      end

      def find_class(name)
        name = name.to_s
        constant_table.map do |key, val|
          return val.as_module if key.data == name
        end

        nil
      end

      def constant(name)
        name = name.to_s
        constant_table.map do |key, val|
          if key.data == name
            if val.dump_kind_of?(@object.decoder.Module)
              return val.as_module
            else
              return val
            end
          end
        end

        nil
      end

      def all_instances
        ary = []
        @object.decoder.objects.each do |obj|
          ary << obj if obj.class_object.id == @object.id
        end

        return Objects.new(ary)
      end

      def metaclass?
        !@object["@attached_instance"].nil?
      end
    end

    Reference = Struct.new(:id)
    Symbol = Struct.new(:id, :data)

    class Symbol
      def ==(other)
        case other
        when String
          data == other
        else
          super
        end
      end

      def <=>(other)
        data <=> other.data
      end

      def to_s
        data
      end
    end

    class Decoder

      Tuple = Struct.new(:objects)
      Bytes = Struct.new(:data)

      def initialize
        @symbols = []
        @objects = []
        @layouts = []
      end

      attr_reader :symbols, :objects, :layouts

      def deref(id)
        if id.kind_of? Reference
          @objects[id.id]
        else
          @objects[id]
        end
      end

      def int
        @f.read(4).unpack("N").first
      end

      def ints(n)
        @f.read(4*n).unpack("N#{n}")
      end

      def short
        @f.read(2).unpack("n").first
      end

      def char
        @f.read(1)[0]
      end

      def decode_reference
        subcmd = @f.read(1)[0]
        case subcmd
        when ?r
          obj = Reference.new(int)
        when ?x
          ref = int
          obj = @symbols[ref]
        when ?s
          id, sz = ints(2)
          obj = Symbol.new(id, @f.read(sz))
          @symbols[id] = obj
        when ?f
          obj = int
        when ?t
          obj = []
          sz = int
          sz.times do
            obj << decode_reference
          end

          obj = Tuple.new(obj)
        when ?b
          obj = Bytes.new(@f.read(int))
        when ?i
          obj = case char
                when 0
                  false
                when 1
                  true
                when 2
                  nil
                end
        else
          raise "invalid sub code - #{subcmd}, #{subcmd.chr}"
        end

        return obj
      end

      def decode(file)
        File.open(file) do |f|
          magic = f.read(12)
          if magic != "RBXHEAPDUMP\0"
            raise "Invalid file format"
          end

          @f = f

          version = int

          unless version == 1
            raise "Invalid version - #{version}"
          end

          while true
            str = @f.read(1)
            break unless str
            cmd = str[0]

            case cmd
            when ?s
              id, sz = ints(2)
              str = @f.read(sz)
              @symbols[id] = str
            when ?o
              id, bytes, layout, klass = ints(4)
              ivar_ref = decode_reference
              syms = short # , syms = @f.read(18).unpack("NNNNn")
              ivars = []

              syms.times do
                ivars << decode_reference
              end

              if @objects[id]
                raise "redefined object #{id}"
              end

              @objects[id] = DumpedObject.new(self, id, bytes,
                                              @layouts[layout],
                                              Reference.new(klass),
                                              Reference.new(ivar_ref), ivars)
            when ?l
              id, sz = ints(2)
              syms = ints(sz)
              @layouts[id] = syms.map { |x| @symbols[x] }
            when ?- # footer
              @object = @objects[int].as_module
              @klass =  @objects[int].as_module
              @module = @objects[int].as_module
            else
              raise "invalid code #{cmd}"
            end
          end
        end

        @included_module = @object.find_class("IncludedModule")
        @f = nil
      end

      def Object
        @object
      end

      def Class
        @klass
      end

      def Module
        @module
      end

      def all_objects
        return Objects.new(@objects)
      end

      def find_references(id)
        out = []
        @objects.each do |o|
          out << o if o.references?(id)
        end

        return out
      end
    end

    class Histogram
      def initialize(data)
        @data = data
      end

      class Entry
        def initialize(klass)
          @klass = klass
          @objects = 0
          @bytes = 0
        end

        attr_reader :objects, :bytes

        def inc(object)
          @objects += 1
          @bytes += object.bytes
        end

        def <=>(other)
          @objects <=> other.objects
        end
      end

      def self.by_class(objects)
        histogram = Hash.new { |h,k| h[k] = Entry.new(k) }

        objects.each do |o|
          klass = o.class_object

          if klass.name
            histogram[klass].inc(o)
          end
        end

        return Histogram.new(histogram)
      end

      def [](cls)
        @data[cls]
      end

      def to_text
        each_sorted do |klass, entry|
          puts "%10d %s (%d bytes)" % [entry.objects, klass.name, entry.bytes]
        end
      end

      def each_sorted
        sorted = @data.to_a.sort_by { |x| x[1] }
        sorted.reverse_each do |klass, entry|
          yield klass, entry
        end
      end
    end

    class Objects
      def initialize(ary)
        @array = ary
      end

      attr_reader :array

      def histogram
        Histogram.by_class(@array)
      end

      def referers
        ary = []

        # Use a hash to speed up checking. Doing a #include? check on @array
        # is pretty slow.
        hsh = {}

        @array.each do |obj|
          hsh[obj.id] = true
        end

        @array[0].decoder.objects.each do |obj|
          obj.ivars.each do |iv|
            ary << obj if iv.kind_of?(Reference) && hsh[iv.id]
          end
        end

        return Objects.new(ary.uniq)
      end

      def size
        @array.size
      end

      def byte_size
        @bytes ||= @array.inject(0) { |acc,o| acc + o.bytes }
      end

      def [](obj)
        @array[obj]
      end

      def inspect
        "#<#{self.class} size=#{size}>"
      end
    end
  end
end

class HeapDumpSession
  def initialize
    puts "RELOADING..."
    @file = ENV['DUMP']
    if File.exists?("#{@file}.marshal")
      @decoder = Marshal.load File.read("#{@file}.marshal")
    else
      @decoder = Rubinius::HeapDump::Decoder.new
      @decoder.decode(@file)
      File.open("#{@file}.marshal", "w") { |f| f << Marshal.dump(@decoder) }
    end
    @histogram = decoder.all_objects.histogram
  end

  attr_reader :decoder, :histogram

  def self.session
    @session ||= new
  end

  def test
    decoder = Rubinius::HeapDump::Decoder.new

    file = ARGV.shift

    decoder.decode(file)

    histogram = decoder.all_objects.histogram

    histogram.to_text

    rubinius = decoder.Object.constant("Rubinius")
    tuple = rubinius.constant("Tuple")

    instances = tuple.all_instances
    p instances.array.size

    ref = instances.referers
    p ref.size
    puts "#{ref.byte_size} bytes"

    hist = ref.histogram
    hist.to_text
  end
end

