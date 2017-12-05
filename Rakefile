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

  desc "Power up dashboard"
  task :docker_env do
    system <<-EOF
      minikube docker-env
    EOF
  end

  desc "Power up minikube"
  task :stop do
    system <<-EOF
      minikube stop
    EOF
  end
end

namespace :spin do
  desc "Setup architecture"
  task :up do
    system <<-EOF
      kubectl create -f kubernetes.scalable/namespace.yaml
      kubectl create -f kubernetes.scalable/manifests
    EOF
  end

  desc "Shutdown architecture"
  task :down do
    system <<-EOF
      kubectl delete -f kubernetes.scalable/manifests
      kubectl delete -f kubernetes.scalable/namespace.yaml
    EOF
  end
end

namespace :docker do
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
end

namespace :images do
  desc "starting logging containers"
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
