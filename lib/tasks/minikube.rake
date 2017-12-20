namespace :minikube do
  desc "Power up minikube"
  task :start do
    system <<-EOF
      minikube --vm-driver=hyperkit --cpus=6 --memory=8192 --disk-size 100g start
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
