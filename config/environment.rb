# Load the rails application
require File.expand_path('../application', __FILE__)


# Set the DUMP environment variable to the heap dump file. For example:
#
#   export DUMP=/path/to/heap.dump
#
ENV['DUMP'] = File.expand_path("heap.dump") unless ENV['DUMP']

# Quick error class for config issue and check for dump file loading
class ConfigurationError < StandardError; end

# Initialize the rails application
Gauge::Application.initialize!
