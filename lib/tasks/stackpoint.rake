namespace :stackpoint do
  namespace :generate do
    desc <<-EOF
      Generate one single yaml for orchestraction.
    EOF
    task :yaml do
      require 'yaml'
      require 'dotenv'
      require 'base64'
      require 'json'

      external_domain   = ENV['DOMAIN'] || 'staging.pushtech.de'
      image_pull_policy = ENV['IMAGE_PULL_POLICY']
      external_services = []
      docs              = Hash.new{|h,k| h[k] = [] }
      website_cdn_hosts =
        ["www1", "www2", "www3"].map { |a| a + "." + external_domain }

      Dir.glob("kubernetes/**/*.yaml").each do |file_name|
        YAML.load_documents( File.read(file_name) ).each do |hsh|
          # name space all the yamls, this is makes it easier to mixin
          # other namespaces (e.g. kube-lego).
          unless hsh["metadata"]["namespace"] ||
                 (hsh["kind"] == "Namespace"   ||
                  hsh["kind"] == "ClusterRole" ||
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

      # need to have the address of the asset server and website
      assets_host, website_host = "",""

      # remove the loadbalancer type from our services since we don't
      # want them to have external IPs, we've got a load balancer
      # (nginx doing ssl termination) for that.
      docs["Service"].each do |serv|
        next if serv["metadata"]["namespace"] != KubernetesNS

        if serv["spec"]["type"] == "LoadBalancer"
          serv["spec"].delete("type")
          serv["spec"]["ports"].first.delete("nodePort")
          external_services << [
            serv["metadata"]["name"],
            serv["metadata"]["annotations"]["subdomain.name"],
            serv["spec"]["ports"].first["port"]
          ]

          case external_services.last.first
          when "website"
            website_host = "https://%s.%s" % [external_services.last[1],
                                              external_domain]
          when "imageserver"
            assets_host = "https://%s.%s" % [external_services.last[1],
                                            external_domain]
          end
        end
      end

      (docs["Namespace"] ||= []).tap do |ns|
        ns << {
          "apiVersion" => "v1",
          "kind" => "Namespace",
          "metadata" => {
            "name" => KubernetesNS
          }
        }
      end

      (docs["Secret"] ||= []).tap do |secrets|
        externals = {
          "WEB_SOCKET_SCHEMA" => "wss",
          "ASSETS_HOST"       => assets_host,
          "LOGIN_HOST"        => website_host,
          "PROFILE_HOST"      => website_host,
          "WEBSITE_CDN_HOSTS" => website_cdn_hosts.join(",")
        }

        [Helpers::Secrets.for_env(KubernetesNS),
         Helpers::Secrets.for_docker(KubernetesNS),
         Helpers::Secrets.for_external_cfg(KubernetesNS, externals),
         Helpers::Secrets.for_internal_cfg(KubernetesNS),
        ].each do |hsh|
          secrets << YAML.load(hsh.values.first.join("\n"))
        end
      end

      docs["Deployment"].each do |depl|
        spec = depl["spec"]["template"]["spec"]

        # replace docker image names with external accessible ones
        spec["containers"].each do |container|
          if container["image"] =~ /pushtech.(.+):v1/
            container["image"] = "index.docker.io/gorenje/pushtech:#{$1}"
          end
          container["imagePullPolicy"] = image_pull_policy if image_pull_policy
        end

        (spec["initContainers"] || []).each do |container|
          if container["image"] =~ /pushtech.(.+):v1/
            container["image"] = "index.docker.io/gorenje/pushtech:#{$1}"
          end
          container["imagePullPolicy"] = image_pull_policy if image_pull_policy
        end
      end

      # replace the existing Ingress, with our generated ones.
      template = docs["Ingress"].first
      docs["Ingress"] = []
      external_services.each do |servname, subdomain, port|
        ingress = YAML.load(template.to_yaml) # deep clone
        domain  = (subdomain || servname) + "." + external_domain

        ingress["metadata"]["name"] = servname

        tls = ingress["spec"]["tls"].first
        tls["hosts"]      = [domain]
        tls["secretName"] = servname + "-tls"

        rule = ingress["spec"]["rules"].first
        rule["host"] = domain
        rule["http"]["paths"].first["backend"] = {
          "serviceName" => servname,
          "servicePort" => port
        }

        docs["Ingress"] << ingress
      end

      # create the cdn servers for the website.
      ingress_template = docs["Ingress"].select do |ingress|
        ingress["metadata"]["name"] == "website"
      end.first

      website_cdn_hosts.each do |cdn_domain|
        ingress = YAML.load(ingress_template.to_yaml) # deep clone
        servname = "website-" + cdn_domain.split(".").first

        ingress["metadata"]["name"] = servname

        tls = ingress["spec"]["tls"].first
        tls["hosts"]      = [cdn_domain]
        tls["secretName"] = servname + "-tls"

        rule = ingress["spec"]["rules"].first
        rule["host"] = cdn_domain

        docs["Ingress"] << ingress
      end

      tstamp = DateTime.now.strftime("%Y%m%d%H%m%S")
      docs.keys.each do |kind|
        outfile_name = "stackpoint.#{kind.downcase}.yaml"
        if File.exists?(outfile_name)
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
