require 'rubygems'
require 'bundler'
require 'bundler/setup'

KubernetesNS = 'pushtech'

namespace :minikube do
  desc "Power up minikube"
  task :start do
    system <<-EOF
      minikube --vm-driver=xhyve --cpus=4 --memory=4096 start
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

    desc "convert all compose files to kubernetes"
    task :convert_to_kubernetes do
      require 'date'
      dirname = "compose.#{DateTime.now.strftime("%H%m%S%d%m%Y")}"
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
  namespace :spin do
    desc "Setup architecture"
    task :up do
      system <<-EOF
        kubectl create -f kubernetes.two/namespace.yaml
        kubectl create -f kubernetes.two/manifests
      EOF
    end

    desc "Shutdown architecture"
    task :down do
      system <<-EOF
        kubectl delete -f kubernetes.two/manifests
        kubectl delete -f kubernetes.two/namespace.yaml
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

  namespace :images do
    desc "rebuild docker images"
    task :rebuild do
      system <<-EOF
        eval $(minikube docker-env)

        for n in src/* ; do
          cd $n
          imagename=`basename $n`
          docker build -t #{KubernetesNS}.${imagename}:v1 .
          cd ../..
        done
      EOF
    end
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
