require 'ostruct'

module Consumers
  module Request
    class UrlHandler

      unless defined?(HttpClient)
        HttpClient = Net::HTTP::Persistent.new('whatever')
        HttpClient.verify_mode = OpenSSL::SSL::VERIFY_NONE
        HttpClient.open_timeout = 3 # default is unlimited
        HttpClient.read_timeout = 3 # default is 60 seconds
      end

      def initialize(hsh)
        @request = hsh
      end

      def fire_url
        url      = @request["url"]
        body     = @request["body"]
        header   = @request["header"]

        response = call(url, body, header)

        status_code = response.code.to_i

        status = case status_code
                 when 200, 204, 302 then :ok
                 when 400 then :missing_parameter
                 else :failed
                 end

        if status != :ok
          $stderr.puts("-"*30)
          $stderr.puts "Response Code: #{response.code}"
          $stderr.puts "--url"
          $stderr.puts url.inspect
          $stderr.puts "--request body"
          $stderr.puts body.inspect
          $stderr.puts "--header"
          $stderr.puts header.inspect
          $stderr.puts "--response body"
          $stderr.puts response.body.inspect
          $stderr.puts("-"*30)
        end

        [status, response.code]
      end

      def call(url, body, header)
        uri = URI.parse(url)
        req = nil

        unless body.blank?
          req = Net::HTTP::Post.new(uri.request_uri)
          req.body = body
        end

        unless header.empty?
          req ||= Net::HTTP::Get.new(uri.request_uri)
          header.each {|key, value| req.add_field(key, value)}
        end

        tries = 0
        begin
          HttpClient.request *[uri, req].compact
        rescue Exception => e
          tries+=1
          STDERR.puts("#{e.class} - #{e.message} for #{uri.inspect} "+
                      "/ TryCount: #{tries}")
          (sleep(0.5) && retry) if tries < 2
          STDERR.puts("#{e.class} - #{e.message} for #{uri.inspect} "+
                      "/ GIVING UP")
          STDERR.puts(e.message)
          OpenStruct.new(:code => 666, :body => e.message)
        end
      end
    end
  end
end
