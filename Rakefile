require 'rubygems'
require 'bundler'
require 'bundler/setup'

KubernetesNS = 'pushtech'

namespace :minikube do
  desc "Power up minikube"
  task :start do
    system <<-EOF
      minikube --vm-driver=xhyve --cpus=6 --memory=8192 start
    EOF
  end

  desc "Power up dashboard"
  task :dashboard do
    system <<-EOF
      minikube dashboard
    EOF
  end

  desc "Show docker environment variables"
  task :docker_env do
    system <<-EOF
      minikube docker-env
    EOF
  end

  desc "Power down minikube"
  task :stop do
    system <<-EOF
      minikube stop
    EOF
  end
end


namespace :docker do
  namespace :images do
    desc "Build all images"
    task :build do
      system <<-EOF
        for n in src/* ; do
          cd $n
          imagename=`basename $n`
          docker build -t #{KubernetesNS}.${imagename}:v1 .
          cd ../..
        done
      EOF
    end
  end

  namespace :compose do
    desc "create all volumes and networks"
    task :create_periphery do
      require 'yaml'
      networks, volumes = [[], []]
      Dir.glob("docker-compose/*").each do |a|
        if nets = YAML.load_file(a)["networks"]
          networks << ((nets["default"]||{})["external"]||{})["name"]
        end
        if vols = YAML.load_file(a)["volumes"]
          volumes << vols.keys
        end
      end

      puts "Creating networks...."
      networks.compact.uniq.each do |networkname|
        print " ... #{networkname}: "
        system "docker network create #{networkname}"
      end

      puts "Creating volumes...."
      volumes.flatten.compact.uniq.each do |volumenname|
        print " ... #{volumenname}: "
        system "docker volume create --name=#{volumenname}"
      end
    end

    desc "spin down everything"
    task :spin_down do
      system <<-EOF
        $(cat .env)
        for n in docker-compose/*.yml ; do
          docker-compose -f $n down
        done
      EOF
    end

    desc "spin up everything"
    task :spin_up do
      system <<-EOF
        $(cat .env)
        for n in docker-compose/*.yml ; do
          docker-compose -f $n up -d
        done
      EOF
    end

    desc "Open pages that are relevant"
    task :open_urls do
      system <<-EOF
        $(cat .env)
        open -a Safari http://localhost:$KAFIDX_PORT/kafidx
        open -a Safari http://localhost:$TRACKER_PORT/event?d=1
        open -a Safari http://localhost:$IMAGE_SERVER_PORT/assets

        open -a Firefox http://localhost:$WEBSITE_PORT
        open -a Firefox http://localhost:$STORAGE_PORT/store/offers
        open -a Firefox http://localhost:$NOTIFICATION_SERVER_PORT/mappings
      EOF
    end

    desc "convert all compose files to kubernetes"
    task :convert_to_kubernetes do
      require 'date'
      dirname = "compose.#{DateTime.now.strftime("%Y%m%d.%H%M%S")}"
      Dir.mkdir(dirname)
      puts ">>>> Generating files into #{dirname}"

      system <<-EOF
        $(cat .env)
        cd #{dirname}
        for n in ../docker-compose/*.yml ; do
          kompose convert -f $n
        done
      EOF

      puts ">>>> Results can be found in #{dirname}"
    end
  end
end

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
      EOF
    end

    desc "Load secrets into minikube"
    task :load do
      if File.exists?(".env")
        require 'dotenv'
        require 'base64'

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

          nodeip     = `minikube ip`.strip
          pgpassword = "nicesecret"
          network    = "pushtech.svc.cluster.local"

          {
            "WEBSITE_PG_PASSWORD" => pgpassword,
            "WEBSITE_DB_URL" => "postgres://postgres:#{pgpassword}@website-db.#{network}:5432/webs",
            "WEBSITE_CDN_HOSTS" => "#{nodeip}:30223",
            "ZOOKEEPER_ENDPOINT" => "zookeeper.#{network}:2181",
          }.to_a.each do |key, value|
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
      EOF
    end
  end

  namespace :spin do
    desc "Setup architecture"
    task :up do
      system <<-EOF
        kubectl create -n #{KubernetesNS} -f kubernetes
      EOF
    end

    desc "Shutdown architecture"
    task :down do
      system <<-EOF
        kubectl delete -n #{KubernetesNS} -f kubernetes
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
    system <<-EOF
      while [ 1 ] ; do
        echo "#######################################################";
        for n in `kubectl get pods -n #{KubernetesNS} | grep #{args.podname} | awk '// { print $1 }'`; do
          echo "======================= $n"
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
      kubectl exec -it ${podname} #{contargs} -n #{KubernetesNS} -- /bin/bash
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
       ab -n #{args.numreq} -c #{args.concurrent} $(minikube service trackersrv -n #{KubernetesNS} --url)/t/#{args.event}?r=#{rand}
    EOF
  end
end

desc "Start a pry shell"
task :shell do
  require 'pry'
  Pry.editor = ENV['PRY_EDITOR'] || ENV['EDITOR'] || 'emacs'
  Pry.start
end

### ignore this stuff.
task :check_env do
  require 'yaml'
  Dir.glob("kubernetes/*deployment*").each do |file_name|
    hsh = YAML.load_file( file_name )
    values = []

    hsh["spec"]["template"]["spec"]["containers"].each do |container|
      (container["env"]||[]).each do |varn|
        next if varn["valueFrom"]
        next if varn["name"] =~ /_HOST$/
        next if ["PORT","COOKIE_SECRET","RACK_ENV"].include?(varn["name"])
        next if varn["name"] == "POSTGRES_PASSWORD" && varn["value"] == "nicesecret"
        values << varn
      end
    end

    unless values.empty?
      puts "==========> #{file_name}"
      values.each {|a| puts a }
    end
  end
end

module Helpers
  module Secrets
    extend self

    def push(file, key, value)
      content = Base64.encode64(value).delete("\n")
      file << "  #{key}: #{content}\n"
    end

    def sendoff
      file_name = File.dirname(__FILE__) + "/secrets.yaml"
      system "kubectl create -n #{KubernetesNS} -f #{file_name}"
      File.unlink(file_name)
    end

    def header(file,name)
      file << ("apiVersion: v1\n"     +
               "kind: Secret\n"       +
               "metadata:\n"          +
               "  name: #{name}\n" +
               "type: Opaque\n"       +
               "data:\n")
    end
  end
end
