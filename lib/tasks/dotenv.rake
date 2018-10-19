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

  def generate_random_username
    [*?A..?Z].sample + ([1]*5).map { [*?a..?z].sample }.join
  end

  def generate_random_password
    ([1]*10).map { [*?A..?Z,*?a..?z,*?0..?9].sample }.join
  end

  def enter_non_blank_value(name)
    loop do
      print "Enter non-blank value for #{name}: "
      val = STDIN.readline.strip
      return val unless val.empty?
    end
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

    class String
      def yes?
        ["","Y","y"].include?(self)
      end
    end

    content = {}

    if File.exists?(".env")
      `mv .env .env.#{DateTime.now.strftime("%Y%m%d%H%m%S")}`
    end

    File.read(".env.template").split("\n").each do |line|
      next if line.strip.empty?

      if line =~ /^export (.+)=#\{(.*)}/
        name, default = $1, $2.strip

        print "#{name} generate the value (#{default}) [Y/n]? "
        response = STDIN.readline.strip
        content[name] =  if response.yes?
                           eval(default)
                         else
                           enter_non_blank_value(name)
                         end

      elsif line =~ /^export (.+)=(.*)/
        name, default = $1, $2.strip
        unless default.empty?
          print "#{name} accept default value (#{default}) [Y/n]? "
          response = STDIN.readline.strip
          content[name] = if response.yes?
                            default
                          else
                            enter_non_blank_value(name)
                          end
        else
          print "Enter value or leave blank for #{name}: "
          content[name] = STDIN.readline.strip
        end

      elsif line =~ /^#/
        puts "\033[0;m\033[1;32m" + line + "\033[0;m"
      end
    end

    File.open(".env", "w+").tap do |f|
      content.each do |key,value|
        f << "export #{key}=#{value}\n"
      end
    end.close
  end
end
