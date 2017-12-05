namespace :berlindekinos do
  desc <<-EOF
    Update the Berlin.de Kinos offers.
  EOF
  task :update => :environment do
    BerlinDeKinosImporter.new.perform
  end

  desc <<-EOF
    Delete all Berlin.de Kinos Offers.
  EOF
  task :delete_all => :environment do
    BerlinDeKinosImporter.new.delete_all
  end
end
