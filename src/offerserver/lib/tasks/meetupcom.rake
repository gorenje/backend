namespace :meetupcom do
  desc <<-EOF
    Update the Meetup.com offers.
  EOF
  task :update => :environment do
    MeetupImporter.new.perform
  end

  desc <<-EOF
    Delete all Meetup.com Offers.
  EOF
  task :delete_all => :environment do
    MeetupImporter.new.delete_all
  end
end
