namespace :berlinnatur do
  desc <<-EOF
    Update the Berlin.de Natur offers.
  EOF
  task :update => :environment do
    BerlinNaturImporter.new.perform
  end

  desc <<-EOF
    Delete all Berlin.de Natur Offers.
  EOF
  task :delete_all => :environment do
    BerlinNaturImporter.new.delete_all
  end
end
