module Helpers
  module Secrets
    extend self

    def push(store, key, value)
      content = Base64.encode64(value).delete("\n")
      store << "  #{key}: #{content}"
    end

    def sendoff(contents)
      file_name = File.dirname(__FILE__) + "/../secrets.yaml"
      (File.open(file_name, "w+") << contents).close
      system "kubectl create -n #{KubernetesNS} -f #{file_name}"
      File.unlink(file_name)
    end

    def header(content, name, opts = {})
      type = opts[:type] || "Opaque"
      content.tap do |c|
        c << "---"
        c << "apiVersion: v1"
        c << "kind: Secret"
        c << "metadata:"
        c << "  name: #{name}"
        c << "  namespace: #{opts[:namespace]}" if opts[:namespace]
        c << "type: #{type}"
        c << "data:"
      end
    end

    def for_docker(namespace = nil)
      # create the auth-token for docker hub to obtain private images.
      secrets_name = "meatdocker"
      content = [].tap do |ctnt|
        Helpers::Secrets.header(ctnt, secrets_name,
                                { :type => "kubernetes.io/dockerconfigjson",
                                  :namespace => namespace})
        hsh = JSON(File.read("#{ENV['HOME']}/.docker/config.json"))
        docker_keys = hsh["auths"].keys.select { |a| a =~ /docker.io/ }
        content = { "auths" =>
                    hsh["auths"].select { |k,v| docker_keys.include?(k) } }
        Helpers::Secrets.push(ctnt, ".dockerconfigjson", content.to_json)
      end
      { secrets_name => content }
    end

    def for_env(namespace = nil)
      # create envsecrets which contains api tokens etc
      secrets_name = "envsecrets"
      require 'dotenv'
      Dotenv.load
      content = [].tap do |ctnt|
        Helpers::Secrets.header(ctnt, secrets_name,
                                {:namespace => namespace})
        File.read(".env").split(/\n/).each do |lne|
          next if lne.empty?
          varname = lne.split(/ /).last.split(/=/).first
          Helpers::Secrets.push(ctnt, varname, ENV[varname])
        end
      end
      { secrets_name => content }
    end

    def for_external_cfg(namespace = nil, overrides = {})
      # create external configuration for urls that need to know the
      # domain or ip of the node or cluster. The port numbers are the
      # nodePorts on the respective services.
      secrets_name = "extcfg"
      nodeip       = `minikube ip`.strip

      content = [].tap do |ctnt|
        Helpers::Secrets.header(ctnt, secrets_name,
                                {:namespace => namespace})
        {
          "WEB_SOCKET_SCHEMA" => "ws",
          "ASSETS_HOST"       => "http://#{nodeip}:30361",
          "LOGIN_HOST"        => "http://#{nodeip}:30223",
          "PROFILE_HOST"      => "http://#{nodeip}:30223",
        }.to_a.each do |key,value|
          Helpers::Secrets.push(ctnt, key, overrides[key] || value)
        end
      end
      { secrets_name => content }
    end

    def for_internal_cfg(namespace = nil)
      # create k8scfg which contains the configuration stuff for kubernetes
      secrets_name = "k8scfg"
      require 'dotenv'
      Dotenv.load
      pgpassword   = "nicesecret"
      network      = "pushtech.svc.cluster.local"

      content = [].tap do |ctnt|
        Helpers::Secrets.header(ctnt, secrets_name,
                                {:namespace => namespace})

        {
          "NOTIFSERVER_REDIS_URL" =>
          "redis://notifserver-redis.#{network}:6379/12",
          "NOTIFSERVER_PG_PASSWORD" => pgpassword,
          "NOTIFSERVER_DB_URL" =>
          "postgres://postgres:#{pgpassword}@notifserver-db.#{network}:5432/notserver",

          "IMGSERVER_PG_PASSWORD" => pgpassword,
          "IMGSERVER_DB_URL" =>
          "postgres://postgres:#{pgpassword}@imgserver-db.#{network}:5432/imgserver",

          "WEBSITE_PG_PASSWORD" => pgpassword,
          "WEBSITE_DB_URL" => "postgres://postgres:#{pgpassword}@website-db.#{network}:5432/webs",

          "ZOOKEEPER_HOST"    =>
            "zookeeper.#{network}:2181",
          "TRACKER_HOST"      =>
            "http://tracker.#{network}:#{ENV['TRACKER_PORT']}",
          "IMAGE_HOST"        =>
            "http://imageserver.#{network}:#{ENV['IMAGE_SERVER_PORT']}",
          "PUSHTECH_API_HOST" =>
            "http://storage.#{network}:#{ENV['STORAGE_PORT']}",
          "NOTIFY_HOST"       =>
            "http://notificationserver.#{network}:#{ENV['NOTIFICATION_SERVER_PORT']}",
        }.to_a.each do |key, value|
          Helpers::Secrets.push(ctnt, key, value)
        end
      end
      { secrets_name => content }
    end
  end
end
