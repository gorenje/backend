namespace :stackpoint do
  namespace :generate do
    desc <<-EOF
      Generate one single yaml for orchestraction.
    EOF
    task :yaml do
      require 'yaml'

      docs              = Hash.new{|h,k| h[k] = [] }
      external_services = []
      external_domain   = ENV['DOMAIN'] || 'staging.pushtech.de'
      # should really get rid of this by mapping our service names to
      # our subdomains. but that would require fixing the readme.
      ServiceMapping = {
        "storage"            => "store",
        "tracker"            => "trk",
        "notificationserver" => "notify",
        "website"            => "www",
        "imageserver"        => "assets",
        "offerserver"        => "offers",
        "consumers-ruby"     => "consumers",
      }

      Dir.glob("kubernetes/**/*.yaml").each do |file_name|
        YAML.load_documents( File.read(file_name) ).each do |hsh|
          # name space all the yamls, this is makes it easier to miss in
          # other namespaces (e.g. kube-lego).
          unless hsh["metadata"]["namespace"] ||
                 (hsh["kind"] == "Namespace" || hsh["kind"] == "ClusterRole" ||
                  hsh["kind"] == "ClusterRoleBinding")
            hsh["metadata"]["namespace"] = KubernetesNS
          end
          docs[hsh["kind"]] << hsh
        end
      end

      # increase the size of our persistent volumes - because we can!
      docs["PersistentVolumeClaim"].each do |volc|
        if volc["spec"]["resources"]["requests"]["storage"] == "100Mi"
          volc["spec"]["resources"]["requests"]["storage"] = "1Gi"
        end
      end

      # remove the loadbalancer type from our services since we don't
      # want them to have external IPs, we've got a load balancer
      # (nginx doing ssl termination) for that.
      docs["Service"].each do |serv|
        next if serv["metadata"]["namespace"] != KubernetesNS

        if serv["spec"]["type"] == "LoadBalancer"
          serv["spec"].delete("type")
          serv["spec"]["ports"].first["port"] = 80
          serv["spec"]["ports"].first.delete("nodePort")
          external_services << serv["metadata"]["name"]
        end
      end

      docs["Deployment"].each do |depl|
        spec = depl["spec"]["template"]["spec"]

        # websocker schema needs to be ssl compatiable
        # not - easily - possible to detect ssl or not since the service
        # sits behind a load balancer doing ssl termination.
        if depl["metadata"]["name"] == "kafidx"
          spec["containers"].each do |container|
            if container["name"] == "kafidx"
              container["env"] << {
                "name" => "WEB_SOCKET_SCHEMA",
                "value" => "wss"
              }
            end
          end
        end

        # replace docker image names with external accessible ones
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

      # replace the existing Ingress, with our generated ones.
      template = docs["Ingress"].first
      docs["Ingress"] = []
      external_services.each do |servname|
        ingress = YAML.load(template.to_yaml) # deep clone
        domain = (ServiceMapping[servname] || servname) + "." + external_domain

        ingress["metadata"]["name"] = servname

        tls = ingress["spec"]["tls"].first
        tls["hosts"]      = [domain]
        tls["secretName"] = servname + "-tls"

        rule = ingress["spec"]["rules"].first
        rule["host"] = domain
        rule["http"]["paths"].first["backend"]["serviceName"] = servname

        docs["Ingress"] << ingress
      end

      docs.keys.each do |kind|
        outfile_name = "stackpoint.#{kind.downcase}.yaml"
        if File.exists?(outfile_name)
          tstamp = DateTime.now.strftime("%H%m%S%d%m%Y")
          `mv #{outfile_name} #{outfile_name}.#{tstamp}`
        end

        File.open(outfile_name,"w+").tap do |out|
          docs[kind].each do |hsh|
            out << (hsh.to_yaml + "\n")
          end
        end.close
      end
    end
  end
end
