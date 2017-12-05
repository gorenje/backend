namespace :abandonedberlin do
  desc <<-EOF
    Update the Abandoned Berlin offers.
  EOF
  task :update => :environment do
    AbandonedBerlinImporter.new.perform
  end

  desc <<-EOF
    Delete all AbandonedBerlin Offers.
  EOF
  task :delete_all => :environment do
    puts AbandonedBerlinImporter.new.delete_all
  end
end
