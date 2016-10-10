desc 'This task is called by the Heroku scheduler add-on'
task update_information: :environment do
  puts 'Updating info...'
  UpdateJob.new.perform
  puts 'done.'
end
