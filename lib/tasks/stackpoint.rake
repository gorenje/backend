namespace :stackpoint do
  namespace :generate do
    desc <<-EOF
      Generate one single yaml for orchestraction.
    EOF
    task :yaml do
      require 'yaml'
      docs = Hash.new{|h,k| h[k] = [] }

      Dir.glob("kubernetes/**/*.yaml").each do |file_name|
        YAML.load_documents( File.read(file_name) ).each do |hsh|
          docs[hsh["kind"]] << hsh
        end
      end

      docs["PersistentVolumeClaim"].each do |volc|
        if volc["spec"]["resources"]["requests"]["storage"] == "100Mi"
          volc["spec"]["resources"]["requests"]["storage"] = "1Gi"
        end
      end

      docs["Service"].each do |serv|
        if serv["spec"]["type"] == "LoadBalancer"
          serv["spec"]["ports"].first["port"] = 80
        end
      end

      docs["Deployment"].each do |depl|
        spec = depl["spec"]["template"]["spec"]
        spec["containers"].each do |container|
          if container["image"] =~ /pushtech.(.+):v1/
            container["image"] = "index.docker.io/gorenje/pushtech:#{$1}"
          end
        end
        (spec["initContainers"] || []).each do |container|
          if container["image"] =~ /pushtech.(.+):v1/
            container["image"] = "index.docker.io/gorenje/pushtech:#{$1}"
          end
        end
      end

      docs.keys.each do |kind|
        outfile_name = "stackpoint.#{kind.downcase}.yaml"
        if File.exists?(outfile_name)
          tstamp = DateTime.now.strftime("%H%m%S%d%m%Y")
          `mv #{outfile_name} #{outfile_name}.#{tstamp}`
        end

        File.open(outfile_name,"w+").tap do |out|
          docs[kind].each { |hsh| out << (hsh.to_yaml + "\n") }
        end.close
      end
    end
  end
end
