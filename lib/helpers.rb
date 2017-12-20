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

    def header(file, name, type = "Opaque")
      file << ("apiVersion: v1\n"     +
               "kind: Secret\n"       +
               "metadata:\n"          +
               "  name: #{name}\n"    +
               "type: #{type}\n"      +
               "data:\n")
    end
  end
end
