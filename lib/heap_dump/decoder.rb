require 'heap_dump/dumped_object'
require 'heap_dump/objects'

module Rubinius
  module HeapDump

    Reference = Struct.new(:id)
    XSymbol = Struct.new(:id, :data)

    class XSymbol
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
          obj = XSymbol.new(id, @f.read(sz))
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
        when ?c
          sz = int
          obj = @f.read(sz)
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

  end
end
