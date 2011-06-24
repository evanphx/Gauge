# Load the rails application
require File.expand_path('../application', __FILE__)

# Set ENV['DUMP'] as such:
ENV['DUMP'] = File.expand_path("heap.dump")

# Quick error class for config issue and check for dump file loading
class ConfigurationError < StandardError; end

if !ENV['DUMP']
  raise ConfigurationError, "Set ENV variable for dump file."
end

# Initialize the rails application
Gauge::Application.initialize!
