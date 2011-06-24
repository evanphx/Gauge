module Rubinius
  module HeapDump
    class Diff
      def initialize(before, after)
        @before = before
        @after = after
      end

      def histogram
        b = Histogram.by_class_name @before.all_objects.array
        a = Histogram.by_class_name @after.all_objects.array

        c = {}

        a.each do |k,e|
          if prev = b[k]
            n = e - prev
            if n.objects != 0
              c[k] = n
            end
          else
            c[k] = e
          end
        end

        Histogram.new(c)
      end
    end
  end
end
