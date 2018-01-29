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

  namespace :resources do
    desc <<-EOF
      Analyse resources measurements.
    EOF
    task :analyse do
      class Array
        def avg
          sum / count.to_f
        end
      end

      datapoints = 0
      namespace  = ""
      cpudata    = Hash.new{|h,k| h[k] = Hash.new{|h2,k2| h2[k2] = [] } }
      memdata    = Hash.new{|h,k| h[k] = Hash.new{|h2,k2| h2[k2] = [] } }

      File.read("last.test.txt").split(/\n/).each do |line|
        next if line.strip.empty?
        if line =~ /Namespace: (.+)/
          namespace = $1
        elsif line =~ /(.+)[[:space:]]+([0-9]+)m[[:space:]]+([0-9]+)Mi/
          cpudata[namespace][$1] << $2.to_i
          memdata[namespace][$1] << $3.to_i
          datapoints += 1
        else
          puts "Warning: Ignoring '#{line}' because it didn't match"
        end
      end

      longest_service_name = cpudata.keys.map do |namespace|
        cpudata[namespace].keys.map do |service|
          service.length + namespace.length
        end
      end.flatten.max

      cnt = 0
      puts("\033[1;32m%#{longest_service_name+2}s %20s %20s\033[0;m" % [
             "pod (namespace) - max (avg,min)".center(longest_service_name),
             "cpu (m)".center(20),
             "memory (Mi)".center(20)])

      cpudata.keys.each do |namespace|
        cpudata[namespace].keys.each do |service|
          cpda = cpudata[namespace][service]
          mmda = memdata[namespace][service]
          clr  = (cnt+=1) % 2 == 1 ? "\033[1;40m" : "\033[1;44m"

          puts(("#{clr}%-#{longest_service_name+3}s %5d (%5d,%5d) "+
                "%5d (%5d,%5d)\033[0;m") % [
                 "#{service} (#{namespace})",
                 cpda.max, cpda.avg, cpda.min, mmda.max, mmda.avg, mmda.min])
        end
      end

      puts("\033[0;m\033[1;32m======> Total Datapoints: " + datapoints.to_s +
           "\033[0;m")
    end

    desc <<-EOF
      Measure the current resource usage.
    EOF
    task :measure do
      system <<-EOF
      for ns in kube-lego nginx-ingress pushtech ; do
        echo "--------> Namespace: $ns"
        for n in `kubectl get pods -n $ns | awk '// { print $1 }' | tail +2` ; do
          kubectl top pod -n $ns $n | tail +2
        done
      done
    EOF
    end
  end
end
