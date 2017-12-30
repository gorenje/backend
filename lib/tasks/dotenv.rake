require 'securerandom'
require 'openssl'
require 'base64'
require 'date'

namespace :dotenv do

  RsaKey    = OpenSSL::PKey::RSA.generate(2048)
  AesCipher = OpenSSL::Cipher::AES.new(128, :CBC)

  def generate_cookie_secret
    SecureRandom.uuid.gsub(/-/,'')
  end

  def generate_cred_key
    "\"#{Base64.encode64(AesCipher.random_key).gsub(/\n/,'\\n')}\""
  end

  def generate_cred_iv
    "\"#{Base64.encode64(AesCipher.random_iv).gsub(/\n/,'\\n')}\""
  end

  def generate_rsa_private_key
    Base64.encode64(RsaKey.export).gsub(/\n/,'')
  end

  def generate_rsa_public_key
    Base64.encode64(RsaKey.public_key.export).gsub(/\n/,'')
  end

  desc <<-EOF
    Interactively generate the .env file
  EOF
  task :generate do
    class NilClass
      def empty?
        true
      end
    end

    content = {}
    last_comment_line = nil

    if File.exists?(".env")
      `mv .env .env.#{DateTime.now.strftime("%Y%m%d%H%m%S")}`
    end

    File.read(".env.template").split("\n").each do |line|
      last_comment_line = line if line =~ /^#/
      next if line.strip.empty?

      if line =~ /^export (.+)=#\{(.*)}/
        name, default = $1, $2.strip
        puts last_comment_line unless last_comment_line.empty?

        print "#{name} generate the value (#{default}) [Y/n]? "
        response = STDIN.getc
        content[name] =  if response =~ /\n/ || response =~ /y/i
                           eval(default)
                         else
                           print "Enter the value: "
                           STDIN.readline.strip
                         end
      elsif line =~ /^export (.+)=(.*)/
        name, default = $1, $2.strip
        unless default.empty?
          print "#{name} accept default value (#{default}) [Y/n]? "
          response = STDIN.getc
          content[name] = if response =~ /\n/ || response =~ /y/i
                            default
                          else
                            print "Enter the value: "
                            STDIN.readline.strip
                          end
        else
          print "Enter the value for #{name}: "
          content[name] = STDIN.readline.strip
        end
      end
    end

    File.open(".env", "w+").tap do |f|
      content.each do |key,value|
        f << "export #{key}=#{value}\n"
      end
    end.close
  end
end
