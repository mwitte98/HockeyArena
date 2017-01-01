# Load the Rails application.
require_relative 'application'

# Load environment vars from local file
env = Rails.root.join('.env')
load(env) if File.exist?(env)

# Initialize the Rails application.
Rails.application.initialize!
