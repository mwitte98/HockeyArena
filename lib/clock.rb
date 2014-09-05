require 'config/boot'
require 'config/environment'
require 'clockwork'

include Clockwork

every(1.day, 'Queue hockey arena jobs', at: '21:00', tz: 'UTC') { U20Job.new.async.perform() }