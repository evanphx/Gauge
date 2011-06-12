# Load the rails application
require File.expand_path('../application', __FILE__)

# Set ENV['DUMP'] as such:
# ENV['DUMP'] = File.expand_path("heap.dump")

# Initialize the rails application
Gauge::Application.initialize!
