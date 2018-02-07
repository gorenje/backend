namespace :meetupcom do
  desc <<-EOF
    Update the Meetup.com offers.
  EOF
  task :update, [:start, :end] => :environment do |t,args|
    MeetupImporter.new.perform({"start" => args.start.to_i,
                                "end"   => args.end.to_i})
  end

  desc <<-EOF
    Delete all Meetup.com Offers.
  EOF
  task :delete_all => :environment do
    MeetupImporter.new.delete_all
  end
end
