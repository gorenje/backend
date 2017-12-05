namespace :drivenow do
  desc <<-EOF
    Update the DriveNow offers.
  EOF
  task :update => :environment do
    DriveNowImporter.new.perform
  end

  desc <<-EOF
    Delete all DriveNow Offers.
  EOF
  task :delete_all => :environment do
    DriveNowImporter.new.delete_all
  end
end
