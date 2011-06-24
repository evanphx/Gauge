require 'heap_dump/decoder'

module Rubinius
  module HeapDump
    def self.open(file)
      dec = Decoder.new

      File.open(file) do |f|

      end
    end
  end
end

class HeapDumpSession
  def initialize
    puts "RELOADING..."
    @file = ENV['DUMP']
    if File.exists?("#{@file}.marshal")
      @decoder = Marshal.load File.read("#{@file}.marshal")
    else
      @decoder = Rubinius::HeapDump::Decoder.new
      @decoder.decode(@file)
      File.open("#{@file}.marshal", "w") { |f| f << Marshal.dump(@decoder) }
    end
    @histogram = decoder.all_objects.histogram
  end

  attr_reader :decoder, :histogram

  def self.session
    @session ||= new
  end

  def test
    decoder = Rubinius::HeapDump::Decoder.new

    file = ARGV.shift

    decoder.decode(file)

    histogram = decoder.all_objects.histogram

    histogram.to_text

    rubinius = decoder.Object.constant("Rubinius")
    tuple = rubinius.constant("Tuple")

    instances = tuple.all_instances
    p instances.array.size

    ref = instances.referers
    p ref.size
    puts "#{ref.byte_size} bytes"

    hist = ref.histogram
    hist.to_text
  end
end

