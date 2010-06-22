module HeapViewerHelper
  def show_object(obj)
    cls = obj.class_object

    case cls.name
    when "Array"
      sz = obj["@total"]
      "#<Array id=#{obj.id} size=#{sz}>"
    when "String"
      total = obj["@num_bytes"]
      data = obj["@data"].data.data[0, total]
      "#<String id=#{obj.id} bytes=#{total} #{data.inspect}>"
    else
      "#<#{obj.class_object.name} id=#{obj.id}>"
    end
  end

  def show_ref(ref)
    sess = HeapDumpSession.session
    case ref
    when Rubinius::HeapDump::Reference
      show_object sess.decoder.deref(ref)
    when Rubinius::HeapDump::Symbol
      "#<Symbol #{ref.data.inspect}>"
    when Array
      ref.map { |x| x.inspect }.join(", ")
    else
      ref.inspect
    end
  end
end
