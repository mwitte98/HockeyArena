desc "This task is called by the Heroku scheduler add-on"
task :update_information => :environment do
  puts "Updating info..."
  U20Job.new.perform()
  puts "done."
end