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
    namespace = ""
    cpudata = Hash.new{|h,k| h[k] = Hash.new{|h2,k2| h2[k2] = [] } }
    memdata = Hash.new{|h,k| h[k] = Hash.new{|h2,k2| h2[k2] = [] } }

    File.read("last.test.txt").split(/\n/).each do |line|
      next if line.strip.empty?
      if line =~ /Namespace: (.+)/
        namespace = $1
      elsif line =~ /(.+)[[:space:]]+([0-9]+)m[[:space:]]+([0-9]+)Mi/
        cpudata[namespace][$1] << $2.to_i
        memdata[namespace][$1] << $3.to_i
        datapoints+=1
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
    puts("%#{longest_service_name+10}s %20s %20s" % [
           "pod (namespace) - max (avg,min)".center(longest_service_name),
           "cpu (m)".center(20),
           "memory (Mi)".center(20)
         ])

    cpudata.keys.each do |namespace|
      cpudata[namespace].keys.each do |service|
        clr = (cnt+=1) % 2 == 1 ? "\033[1;31m" : "\033[1;32m"
        puts("#{clr}%-#{longest_service_name+3}s %5d (%5d,%5d) %5d (%5d,%5d)" % [
               "#{service} (#{namespace})",
               cpudata[namespace][service].max,
               cpudata[namespace][service].avg,
               cpudata[namespace][service].min,
               memdata[namespace][service].max,
               memdata[namespace][service].avg,
               memdata[namespace][service].min
             ])
      end
    end

    puts("======> Total Datapoints: " + datapoints.to_s)
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
