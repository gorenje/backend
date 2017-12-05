namespace :berlinde do
  desc <<-EOF
    Update the Berlin.de offers.
  EOF
  task :update => :environment do
    BerlinDeImporter.new.perform
  end

  desc <<-EOF
    Delete all Berlin.de Offers.
  EOF
  task :delete_all => :environment do
    BerlinDeImporter.new.delete_all
  end
end
