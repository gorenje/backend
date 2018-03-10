namespace :export do
  def dog_dump(hsh, file)
    YAML.dump((hsh.tap do |h|
               hsh["images"] = hsh["images"].map do |img_path|
                 r = RestClient.get(ENV['IMAGE_HOST'] + img_path)
                 {
                   :type => r.headers[:content_type],
                   :content => Base64.encode64(r.body).gsub(/\n/,'')
                 }
               end
             end),file)
  end

  def makedir(dirname)
    if File.exists?(dirname)
      `mv #{dirname} #{dirname}.#{DateTime.now.strftime("%Y%m%d%H%m%S")}`
    end
    `mkdir #{dirname}`
  end

  namespace :searches do
    desc <<-EOF
      Export all searches for an Owner.
    EOF
    task :for_owner, [:owner] => :environment do |t,args|
      dirname = "backup.searches.#{args[:owner]}"
      makedir(dirname)

      StoreHelper::Agent.new.searches.
        get({:owner => args[:owner]}.to_query)["data"].each do |hsh|
        File.open(dirname + "/" + hsh["_id"] + ".yaml", "w+").tap do |f|
          dog_dump(hsh, f)
        end.close
      end
    end
  end

  namespace :offers do
    desc <<-EOF
      Export all offers for an Owner.
    EOF
    task :for_owner, [:owner] => :environment do |t,args|
      dirname = "backup.offers.#{args[:owner]}"
      makedir(dirname)

      StoreHelper::Agent.new.bulk.offers.send(args[:owner]).get["data"].
        each do |hsh|
        File.open(dirname + "/" + hsh["_id"] + ".yaml", "w+").tap do |f|
          dog_dump(hsh, f)
        end.close
      end
    end
  end
end
