namespace :reactnative do
  namespace :generate do
    desc <<-EOF
      Generate the required basic auths for the frontend client.
    EOF
    task :basic_auth do
      require 'base64'
      # there a total of three that need generating
      ["PUSHTECH", "NOTIFICATION", "IMAGESERVER"].each do |keyprefix|
        usr,pwd = ["_API_USER", "_API_PASSWORD"].map { |a| keyprefix + a }
        passstr = Base64::encode64("#{ENV[usr]}:#{ENV[pwd]}").strip
        puts "export const #{keyprefix}_AUTH = '#{passstr}'"
      end
    end
  end
end
