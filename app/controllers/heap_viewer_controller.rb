require 'read_dump'

class HeapViewerController < ApplicationController
  def show
    @session = HeapDumpSession.session
    @histogram = @session.histogram
    @classes = []

    @session.decoder.Object.constant_table.each do |name, val|
      if val.kind_of? Rubinius::HeapDump::DumpedObject
        @classes << [name.data, val] if val.dump_kind_of? @session.decoder.Module
      end
    end

    @classes.sort! { |a,b| a[0] <=> b[0] }
  end

  def show_class
    id = params[:id].to_i

    @session = HeapDumpSession.session
    cls = @session.decoder.objects[id].as_module
    @class = cls

    if cls.dump_kind_of?(@session.decoder.Class)
      @mod_or_class = "Class"
    else
      @mod_or_class = "Module"
    end

    @stats = @session.histogram[@class]

    @classes = []
    @values = []

    cls.constant_table.each do |name, val|
      if val.kind_of? Rubinius::HeapDump::DumpedObject
        @classes << [name.data, val] if val.dump_kind_of? @session.decoder.Module
      else
        @values << [name.data, val] if name
      end
    end

    @classes.sort! { |a,b| a[0] <=> b[0] }
    @values.sort!  { |a,b| a[0] <=> b[0] }

    @instance_methods = []

    cls.method_table.each do |name, method, vis|
      @instance_methods << [name, method]
    end

    @instance_methods.sort! { |a,b| a[0] <=> b[0] }

    raw = cls.direct_class_object
    if raw.metaclass?
      @class_methods = []

      raw.method_table.each do |name, method, vis|
        @class_methods << [name, method]
      end

      @class_methods.sort! { |a,b| a[0] <=> b[0] }
    else
      @class_methods = []
    end
  end

  def show_instances
    id = params[:id].to_i

    @session = HeapDumpSession.session
    cls = @session.decoder.objects[id].as_module
    @class = cls

    @instances = cls.all_instances
    @referers = @instances.referers
  end

  def show_object
    id = params[:id].to_i
    @session = HeapDumpSession.session
    @object = @session.decoder.objects[id]
  end
end
