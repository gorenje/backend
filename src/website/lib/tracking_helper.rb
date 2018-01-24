require 'rest-client'

module TrackerHelper
  extend self

  def offer_preview(params)
    params = params.merge(:action => "preview")
    _get("/offr?#{URI.encode_www_form(params)}")
  end

  def search_for_offers(params)
    params = params.merge(:action => "search")
    _get("/offr?#{URI.encode_www_form(params)}")
  end

  def search_for_searches(params)
    params = params.merge(:action => "search")
    _get("/srch?#{URI.encode_www_form(params)}")
  end

  private

  def _get(path)
    RestClient.get($hosthandler.tracker.url + path) rescue nil
  end
end
