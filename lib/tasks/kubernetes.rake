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

        [
          Helpers::Secrets.for_env,
          Helpers::Secrets.for_docker,
          Helpers::Secrets.for_external_cfg,
          Helpers::Secrets.for_internal_cfg,
        ].each do |hsh|
          Helpers::Secrets.sendoff(hsh.values.first.join("\n"))
        end
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
