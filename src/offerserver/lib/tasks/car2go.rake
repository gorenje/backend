namespace :car2go do
  desc <<-EOF
    Update the Car2Go offers.
  EOF
  task :update => :environment do
    CarToGoImporter.new.perform
  end

  desc <<-EOF
    Delete all Car2Go Offers.
  EOF
  task :delete_all => :environment do
    CarToGoImporter.new.delete_all
  end
end
