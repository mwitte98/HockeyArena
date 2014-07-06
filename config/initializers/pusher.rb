require 'pusher'

Pusher.url = "http://#{ENV['pusher_key']}:#{ENV['pusher_secret']}@api.pusherapp.com/apps/#{ENV['pusher_id']}"
Pusher.logger = Rails.logger