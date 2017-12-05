namespace :appjson do
  desc "Generate a .env file for what is required"
  task :to_dotenv do
    require 'json'

    cfg = JSON(File.read("app.json"))
    key = OpenSSL::PKey::RSA.generate(2048)
    cipher = OpenSSL::Cipher::AES.new(128, :CBC)
    cipher.encrypt

    if File.exists?(".env")
      `mv .env .env.#{DateTime.now.strftime("%H%m%S%d%m%Y")}`
    end

    File.open('.env', "w+") do |file|
      file << "## Environment for #{cfg["name"]}"

      cfg["env"].each do |name, hsh|
        req = (hsh["required"]==false) ? "No" : "Yes"
        hsh['value'] = if hsh['generator'] == "secret"
                         SecureRandom.uuid.gsub(/-/,'')
                       else
                         case name
                         when "DATABASE_URL"
                           "postgres://user:pass@localhost:5432/databasename"
                         when "RACK_ENV"
                           "development"
                         when "RSA_PRIVATE_KEY"
                           "\"#{key.export.gsub(/\n/,'\\n')}\""
                         when "RSA_PUBLIC_KEY"
                           "\"#{key.public_key.export.gsub(/\n/,'')}\""
                         when "CRED_KEY_BASE64"
                           val = Base64.encode64(cipher.random_key)
                           "\"#{val.gsub(/\n/,'\\n')}\""
                         when "CRED_IV_BASE64"
                           val = Base64.encode64(cipher.random_iv)
                           "\"#{val.gsub(/\n/,'\\n')}\""
                         else
                           hsh["value"]
                         end
                       end

        file << ["## #{hsh["description"]} (Required? #{req})",
                 "#{name}=#{hsh['value']}", "", ""].join("\n")
      end
    end
  end

  desc "Verify the app.json"
  task :verify do
    require 'json'

    cfg = JSON(File.read("app.json"))
    raise "Name too long, #{cfg["name"].size} > 30" if cfg["name"].size > 30
    puts "Seems ok"
  end
end
