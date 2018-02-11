module ImageHelper
  extend self

  @@cache = {}

  def _base_url
    host = $hosthandler.image
    user, pass = ["USER","PASSWORD"].map { |a| ENV["IMAGE_API_#{a}"] }
    "#{host.protocol}://#{user}:#{pass}@#{host.host}/"
  end


  def upload_url(urlstr)
    return nil if urlstr.empty?

    sha = Digest::SHA256.hexdigest(urlstr)
    return @@cache[sha] if @@cache[sha]

    response = RestClient::Request.
                 execute(:method => "get",
                         :url => _base_url + "asset/#{sha}/available",
                         :max_redirects => 0) { |resp,req,res| resp }

    return (@@cache[sha] = response.body) if response.code == 200

    extname = File.basename(URI.parse(urlstr).path) rescue return

    file = Tempfile.open(["prefix", extname]) do |fh|
      fh << RestClient.get(urlstr) rescue return
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
