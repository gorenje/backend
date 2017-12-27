module ImageHelper
  extend self

  def _base_url
    host = $hosthandler.image
    user, pass = ["USER","PASSWORD"].map { |a| ENV["IMAGE_API_#{a}"] }
    "#{host.protocol}://#{user}:#{pass}@#{host.host}/"
  end


  def upload_url(urlstr)
    extname = File.basename(URI.parse(urlstr).path)
    file    = Tempfile.open(["prefix", extname]) do |fh|
      fh << RestClient.get(urlstr)
    end

    begin
      RestClient.post(_base_url + "assets/upload",
                      { :file => File.open(file), :multipart => true})
    rescue Exception => e
      nil
    ensure
      File.unlink(file) rescue nil
    end
  end
end
