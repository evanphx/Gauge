require 'heap_dump/dumped_module'

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
  end
end
