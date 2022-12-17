require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'rails/test_unit/railtie'
require 'active_support/core_ext/integer/time'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module HockeyArena
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.

    # Prepend all log lines with the following tags.
    config.log_tags = [:request_id, :remote_ip, proc do |request|
      request.headers.select { |key, _value| key.start_with?('HTTP') && key != 'HTTP_COOKIE' }.to_a.to_s
    end]
  end
end
