require 'heap_dump/histogram'

module Rubinius
  module HeapDump
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
