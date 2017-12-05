require 'rest-client'

module TrackerHelper
  extend self

  def chat_message(params)
    params = {
      :churl => (params["channel"] || {})["channel_url"],
      :chnam => (params["channel"] || {})["name"],
      :snder => (params["sender"]  || {})["user_id"],
      :mbers => (params["members"] || []).map { |a| a["user_id"] },
      :msg   => (params["payload"] || {})["message"]
    }

    url = $hosthandler.tracker.url + "/chm?#{URI.encode_www_form(params)}"
    RestClient.get(url) rescue nil
  end

  def match_found(offr, srch)
    params = {
      :oid   => offr.id,
      :olat  => offr.lat,
      :olng  => offr.lng,
      :olatd => offr.latD,
      :olngd => offr.lngD,

      :sid   => srch.id,
      :slat  => srch.lat,
      :slng  => srch.lng,
      :slatd => srch.latD,
      :slngd => srch.lngD,
    }

    url = $hosthandler.tracker.url + "/mtf?#{URI.encode_www_form(params)}"
    RestClient.get(url) rescue nil
  end
end
