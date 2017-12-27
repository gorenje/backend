namespace :luftdaten do
  desc <<-EOF
    Update the Luftdaten offers.
  EOF
  task :update => :environment do
    LuftDatenImporter.new.perform
  end

  desc <<-EOF
    Delete all Luftdaten Offers.
  EOF
  task :delete_all => :environment do
    LuftDatenImporter.new.delete_all
  end
end
