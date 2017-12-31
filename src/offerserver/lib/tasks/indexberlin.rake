namespace :indexberlin do
  desc <<-EOF
    Update the Index Berlin offers.
  EOF
  task :update => :environment do
    IndexBerlinImporter.new.perform
  end

  desc <<-EOF
    Delete all Index Berlin Offers.
  EOF
  task :delete_all => :environment do
    IndexBerlinImporter.new.delete_all
  end
end
