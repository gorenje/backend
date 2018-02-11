namespace :dbpediaorg do
  desc <<-EOF
    Update the DBPedia.Org offers.
  EOF
  task :update, [:char] => :environment do |t,args|
    DbpediaOrgImporter.new.perform({"char" => args.char})
  end

  desc <<-EOF
    Delete all DBPedia.Org Offers.
  EOF
  task :delete_all => :environment do
    DbpediaOrgImporter.new.delete_all
  end
end
