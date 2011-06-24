module Rubinius
  module HeapDump
    class Histogram
      class Entry
        def initialize(klass, objects=0, bytes=0)
          @klass = klass
          @objects = objects
          @bytes = bytes
        end

        attr_reader :objects, :bytes

        def inc(object)
          @objects += 1
          @bytes += object.bytes
        end

        def <=>(other)
          @objects <=> other.objects
        end

        def -(other)
          objects = @objects - other.objects
          bytes = @bytes - other.bytes

          Entry.new(@klass, objects, bytes)
        end
      end

      def initialize(data)
        @data = data
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

      def self.by_class_name(objects)
        histogram = Hash.new { |h,k| h[k] = Entry.new(k) }

        objects.each do |o|
          klass = o.class_object

          if n = klass.name
            histogram[n].inc(o)
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

      def each
        @data.each do |k,e|
          yield k, e
        end
      end

      def each_sorted
        sorted = @data.to_a.sort_by { |x| x[1] }
        sorted.reverse_each do |klass, entry|
          yield klass, entry
        end
      end
    end
  end
end
