require 'heap_dump/specializer'
require 'heap_dump/dumped_lookup_table'
require 'heap_dump/dumped_method_table'

module Rubinius
  module HeapDump
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
        @constants ||= DumpedLookupTable.new(@object["@constant_table"])
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
          return val.as_module if val and key.data == name
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

  end
end
