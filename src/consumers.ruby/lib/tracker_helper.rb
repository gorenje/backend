require 'rest-client'

module TrackerHelper
  extend self

  def bulk_update_done(owner)
    params = {
      :owner => owner
    }

    url = $hosthandler.tracker.url + "/bud?#{URI.encode_www_form(params)}"
    RestClient.get(url) rescue nil
  end
end
