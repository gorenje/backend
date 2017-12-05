module ImageHelper
  extend self

  def upload_url(urlstr)
    extname = File.basename(URI.parse(urlstr).path)
    file    = Tempfile.open(["prefix", extname]) do |fh|
      fh << RestClient.get(urlstr)
    end

    begin
      RestClient.post($hosthandler.image.url+ "/assets/upload",
                      { :file => File.open(file), :multipart => true})
    rescue Exception => e
      nil
    ensure
      File.unlink(file) rescue nil
    end
  end
end
