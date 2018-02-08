namespace :newstralcom do
  desc <<-EOF
    Update the Newstral.Com offers.
  EOF
  task :update, [:country_code] => :environment do |t,args|
    NewstralComImporter.new.perform({"cc" => args.country_code})
  end

  desc <<-EOF
    Delete all Newstral.Com Offers.
  EOF
  task :delete_all => :environment do
    NewstralComImporter.new.delete_all
  end
end
