require 'heap_dump/specializer'

module Rubinius
  module HeapDump
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
  end
end
