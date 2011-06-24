module Rubinius
  module HeapDump
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
  end
end
