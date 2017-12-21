namespace :docker do
  namespace :images do
    desc "Build all images"
    task :build do
      system <<-EOF
        for n in src/* ; do
          cd $n
          imagename=`basename $n`
          echo "!!! Building ====> ${imagename}"
          docker build -t #{KubernetesNS}.${imagename}:v1 .
          cd ../..
        done
      EOF
    end

    desc "Push to hub.docker.com into private repo"
    task :push do
      system <<-EOF
        for n in src/* ; do
          imagename=`basename $n`
          echo "!!! Pushing ====> ${imagename}"
          docker tag #{KubernetesNS}.${imagename}:v1 gorenje/pushtech:${imagename}
          docker push gorenje/pushtech:${imagename}
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
