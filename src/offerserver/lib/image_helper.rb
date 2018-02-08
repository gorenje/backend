module ImageHelper
  extend self

  @@cache = {}

  def _base_url
    host = $hosthandler.image
    user, pass = ["USER","PASSWORD"].map { |a| ENV["IMAGE_API_#{a}"] }
    "#{host.protocol}://#{user}:#{pass}@#{host.host}/"
  end


  def upload_url(urlstr)
    sha = Digest::SHA256.hexdigest(urlstr)
    return @@cache[sha] if @@cache[sha]

    extname = File.basename(URI.parse(urlstr).path)
    file    = Tempfile.open(["prefix", extname]) do |fh|
      fh << RestClient.get(urlstr)
    end

    begin
      r = RestClient.post(_base_url + "assets/upload_with_sha/#{sha}",
                          { :file => File.open(file), :multipart => true})
      @@cache[sha] = r
    rescue Exception => e
      nil
    ensure
      File.unlink(file) rescue nil
    end
  end
end
