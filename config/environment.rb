# Load the rails application
require File.expand_path('../application', __FILE__)
# Load environment vars from local file
env = File.join(Rails.root, '.env')
load(env) if File.exist?(env)
# Initialize the rails application
Rails.application.initialize!
