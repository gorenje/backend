namespace :kubernetes do
  namespace :namespace do
    desc "Create namespace"
    task :create do
      system <<-EOF
        kubectl create namespace #{KubernetesNS}
      EOF
    end

    desc "Delete namespace"
    task :delete do
      system <<-EOF
        kubectl delete namespace #{KubernetesNS}
      EOF
    end
  end

  namespace :secrets do
    desc "Show the current secrets"
    task :show do
      system <<-EOF
        kubectl get secret envsecrets -o yaml -n #{KubernetesNS}
        kubectl get secret k8scfg -o yaml -n #{KubernetesNS}
        kubectl get secret meatdocker -o yaml -n #{KubernetesNS}
        kubectl get secret extcfg -o yaml -n #{KubernetesNS}
      EOF
    end

    desc "Load secrets into minikube"
    task :load do
      if File.exists?(".env")
        require 'dotenv'
        require 'base64'
        require 'json'

        # create envsecrets which contains api tokens etc
        Dotenv.load
        File.open("secrets.yaml", "w+").tap do |file|
          Helpers::Secrets.header(file, "envsecrets")
          File.read(".env").split(/\n/).each do |lne|
            next if lne.empty?
            varname = lne.split(/ /).last.split(/=/).first
            Helpers::Secrets.push(file, varname, ENV[varname])
          end
        end.close

        Helpers::Secrets.sendoff

        # create k8scfg which contains the configuration stuff for kubernetes
        File.open("secrets.yaml", "w+").tap do |file|
          Helpers::Secrets.header(file, "k8scfg")

          pgpassword = "nicesecret"
          network    = "pushtech.svc.cluster.local"

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
            "NOTIFY_HOST"        =>
              "http://notificationserver.#{network}:#{ENV['NOTIFICATION_SERVER_PORT']}",
          }.to_a.each do |key, value|
            Helpers::Secrets.push(file, key, value)
          end
        end.close

        Helpers::Secrets.sendoff

        # create the login for docker hub to obtain private images.
        File.open("secrets.yaml", "w+").tap do |file|
          Helpers::Secrets.header(file, "meatdocker",
                                  "kubernetes.io/dockerconfigjson")
          hsh = JSON(File.read("#{ENV['HOME']}/.docker/config.json"))
          docker_keys = hsh["auths"].keys.select { |a| a =~ /docker.io/ }
          content = { "auths" =>
                      hsh["auths"].select { |k,v| docker_keys.include?(k) } }
          Helpers::Secrets.push(file, ".dockerconfigjson", content.to_json)
        end.close
        Helpers::Secrets.sendoff

        # create external configuration for urls that need to know the
        # domain or ip of the node or cluster. The port numbers are the
        # nodePorts on the respective services.
        nodeip = `minikube ip`.strip
        File.open("secrets.yaml", "w+").tap do |file|
          Helpers::Secrets.header(file, "extcfg")
          {
            "WEB_SOCKET_SCHEMA"    => "ws",
            "EXTERNAL_ASSETS_HOST" => "http://#{nodeip}:30361",
            "LOGIN_HOST"           => "http://#{nodeip}:30223",
            "PROFILE_HOST"         => "http://#{nodeip}:30223",
          }.to_a.each do |key,value|
            Helpers::Secrets.push(file, key, value)
          end
        end.close
        Helpers::Secrets.sendoff
      else
        puts "ERROR: no .env file to convert"
        Kernel.exit(1)
      end
    end

    desc "Remove all secrets from minikube"
    task :delete do
      system <<-EOF
        kubectl delete secret envsecrets -n #{KubernetesNS}
        kubectl delete secret k8scfg -n #{KubernetesNS}
        kubectl delete secret meatdocker -n #{KubernetesNS}
        kubectl delete secret extcfg -n #{KubernetesNS}
      EOF
    end
  end

  namespace :spin do
    desc "Setup architecture"
    task :up do
      system <<-EOF
        kubectl create -n #{KubernetesNS} -f kubernetes/persistentvolumes.yaml
        kubectl create -n #{KubernetesNS} -f kubernetes/dbs
        kubectl create -n #{KubernetesNS} -f kubernetes/workers
        kubectl create -n #{KubernetesNS} -f kubernetes/servers
      EOF
    end

    desc "Shutdown architecture"
    task :down do
      system <<-EOF
        kubectl delete -n #{KubernetesNS} -f kubernetes/servers
        kubectl delete -n #{KubernetesNS} -f kubernetes/workers
        kubectl delete -n #{KubernetesNS} -f kubernetes/dbs
      EOF
    end
  end

  namespace :prune do
    desc "Remove unused images"
    task :images do
      system <<-EOF
        eval $(minikube docker-env)
        docker image prune
      EOF
    end

    desc "Remove unused containers"
    task :containers do
      system <<-EOF
        eval $(minikube docker-env)
        docker container prune
      EOF
    end
  end

  desc "Process list"
  task :ps do
    system <<-EOF
      eval $(minikube docker-env)
      docker ps
    EOF
  end

  desc "starting logging containers"
  task :log, [:podname,:container] do |t,args|
    # Much better with watch:
    #    watch "kubectl logs -n pushtech consumers-nodejs-stats-consumer-57d7477c8d-zdw6s | tail -30"
    # but the following code handles several pods with the same prefix
    system <<-EOF
      while [ 1 ] ; do
        echo "#######################################################";
        for n in `kubectl get pods -n #{KubernetesNS} | grep #{args.podname} | awk '// { print $1 }'`; do
          echo "======================= kubectl logs -n #{KubernetesNS} $n #{args.container} \| tail -50"
          kubectl logs -n #{KubernetesNS} $n #{args.container} | tail -50
        done
      done
    EOF
  end

  desc "start shell in container"
  task :shell, [:podname,:container] do |t,args|
    contargs = args.container.nil? ? "" : "-c #{args.container}"
    system <<-EOF
      podname=`kubectl get pods -n #{KubernetesNS} | grep #{args.podname} | awk '// { print $1 }' | head -1`
      kubectl exec -it ${podname} #{contargs} -n #{KubernetesNS} -- /bin/bash ||
        kubectl exec -it ${podname} #{contargs} -n #{KubernetesNS} -- /bin/sh
    EOF
  end

  desc "Scale something"
  task :scale, [:podname,:to] do |t,args|
    system <<-EOF
      kubectl scale --replicas=#{args.to} -n #{KubernetesNS} deployment/#{args.podname}
    EOF
  end

  desc "Show all resources"
  task :ps do
    system <<-EOF
      kubectl get all -n #{KubernetesNS}
    EOF
  end

  desc "Start a load test on tracking"
  task :loadtest, [:numreq,:concurrent,:event] do |t,args|
    system <<-EOF
       ab -n #{args.numreq} -c #{args.concurrent} $(minikube service tracker -n #{KubernetesNS} --url)/t/#{args.event}?r=#{rand}
    EOF
  end
end
