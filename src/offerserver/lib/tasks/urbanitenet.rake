namespace :urbanitenet do
  desc <<-EOF
    Update the UrbanNite offers.
  EOF
  task :update => :environment do
    UrbaniteNetImporter.new.perform
  end

  desc <<-EOF
    Delete all UrbanNite Offers.
  EOF
  task :delete_all => :environment do
    UrbaniteNetImporter.new.delete_all
  end
end
