require 'heap_dump/specializer'

module Rubinius
  module HeapDump
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
  end
end
