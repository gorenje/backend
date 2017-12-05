namespace :exberliner do
  desc <<-EOF
    Update the Exberliner offers.
  EOF
  task :update => :environment do
    ExberlinerImporter.new.perform
  end

  desc <<-EOF
    Delete all Exberliner Offers.
  EOF
  task :delete_all => :environment do
    ExberlinerImporter.new.delete_all
  end
end
