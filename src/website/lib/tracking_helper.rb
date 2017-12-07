require 'rest-client'

module TrackerHelper
  extend self

  def offer_preview(params)
    params = params.merge(:action => "preview")
    url = $hosthandler.tracker.url + "/offr?#{URI.encode_www_form(params)}"
    RestClient.get(url) rescue nil
  end
end
