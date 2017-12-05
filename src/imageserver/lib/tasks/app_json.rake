namespace :appjson do
  desc "Generate a .env file for what is required"
  task :to_dotenv => :environment do
    require 'json'

    if File.exists?(".env")
      `mv .env .env.#{DateTime.now.strftime("%H%m%S%d%m%Y")}`
    end
    cfg = JSON(File.read("app.json"))

    File.open('.env', "w+") do |file|
      file << "## Environment for #{cfg["name"]}"

      ## Heroku includes this automagically, but it's not available
      ## locally.
      unless cfg["env"]["DATABASE_URL"]
        cfg["env"]["DATABASE_URL"] = {
          "description" => "Connection string for the database.",
          "value" => "postgres://dbuser:password@localhost:5432/wetto"
        }
      end

      unless cfg["env"]["REDISTOGO_URL"]
        cfg["env"]["REDISTOGO_URL"] = {
          "description" => "Connectin string for redis.",
          "value" => "redis://localhost:6379/12"
        }
      end

      cfg["env"]["RACK_ENV"]["value"] = "development" if cfg["env"]["RACK_ENV"]

      cfg["env"].each do |name, hsh|
        req = (hsh["required"]==false) ? "No" : "Yes"
        hsh['value'] = if hsh['generator'] == "secret"
                         SecureRandom.uuid.gsub(/-/,'')
                       else
                         hsh["value"]
                       end

        file << ["## #{hsh["description"]} (Required? #{req})",
                 "#{name}=#{hsh['value']}", "", ""].join("\n")
      end
    end
  end

  desc "Verify the app.json"
  task :verify => :environment do
    require 'json'

    cfg = JSON(File.read("app.json"))
    raise "Name too long, #{cfg["name"].size} > 30" if cfg["name"].size > 30
    puts "Seems ok"
  end
end
