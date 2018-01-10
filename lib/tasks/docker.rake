namespace :docker do
  namespace :images do
    desc "Build all images"
    task :build do
      system <<-EOF
        for n in src/* ; do
          cd $n
          imagename=`basename $n`
          tagname="#{KubernetesNS}.${imagename}"
          prevversion=`docker images -a | grep ${tagname} | grep v1 | awk 'BEGIN { yes=0 } // { print $3; yes=1; } END { if (yes==0) { print "- unknown -" }}'`
          echo "\\033[1;31m!!! \\033[0;35mBuilding ====> ${imagename} \\033[0m"
          docker build -t ${tagname}:v1 .
          echo "\\033[1;31m===>\\033[0m Prev version: \\033[0;31m${prevversion}\\033[0m of ${tagname}"
          cd ../..
        done
      EOF
    end

    desc "Push to hub.docker.com into private repo"
    task :push do
      docker_account = ENV['DOCKER_ACCOUNT'] || 'gorenje'
      system <<-EOF
        for n in src/* ; do
          imagename=`basename $n`
          echo "!!! Pushing \\033[0;31m ====> ${imagename} \\033[0m"
          docker tag #{KubernetesNS}.${imagename}:v1 #{docker_account}/#{KubernetesNS}:${imagename}
          docker push #{docker_account}/#{KubernetesNS}:${imagename}
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
        for n in docker-compose/*.yml ; do
          echo "\\033[0;34m ====> $n \\033[0m"
          docker-compose -f $n down
        done
      EOF
    end

    desc "spin up everything"
    task :spin_up do
      system <<-EOF
        for n in docker-compose/*.yml ; do
          echo "\\033[0;31m ====> $n \\033[0m"
          docker-compose -f $n up -d
        done
      EOF
    end

    desc "Open pages that are relevant"
    task :open_urls do
      system <<-EOF
        open -a Safari http://localhost:#{ENV['KAFIDX_PORT']}/kafidx
        open -a Safari http://localhost:#{ENV['TRACKER_PORT']}/event?d=1
        open -a Safari http://localhost:#{ENV['IMAGE_SERVER_PORT']}/assets

        open -a Firefox http://localhost:#{ENV['WEBSITE_PORT']}
        open -a Firefox http://localhost:#{ENV['STORAGE_PORT']}/store/offers
        open -a Firefox http://localhost:#{ENV['NOTIFICATION_SERVER_PORT']}/mappings
      EOF
    end

    desc "convert all compose files to kubernetes"
    task :convert_to_kubernetes do
      require 'date'
      dirname = "compose.#{DateTime.now.strftime("%Y%m%d.%H%M%S")}"
      Dir.mkdir(dirname)
      puts ">>>> Generating files into #{dirname}"

      system <<-EOF
        cd #{dirname}
        for n in ../docker-compose/*.yml ; do
          kompose convert -f $n
        done
      EOF

      puts ">>>> Results can be found in #{dirname}"
    end
  end
end
