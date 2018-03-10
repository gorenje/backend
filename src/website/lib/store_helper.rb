require 'rest-client'

module StoreHelper
  extend self

  class Agent
    Header = {
      :content_type => "application/json",
      :accept       => "application/json"
    }

    def initialize
      @actions = []
    end

    def method_missing(name, *args)
      @actions << name
      self
    end

    def _base_url
      host = $hosthandler.pushtech_api
      user, pass = ["USER","PASSWORD"].map { |a| ENV["PUSHTECH_API_#{a}"] }
      "#{host.protocol}://#{user}:#{pass}@#{host.host}/"
    end

    def get(params = "")
      JSON(RestClient.get(_base_url + @actions.join("/")+"?#{params}", Header))
    end

    def post(data)
      JSON(RestClient.post(_base_url + @actions.join("/"), data.to_json,Header))
    end

    def put(data)
      JSON(RestClient.put(_base_url + @actions.join("/"), data.to_json,Header))
    end

    def delete
      JSON(RestClient.delete(_base_url + @actions.join("/"), Header))
    end
  end

  def new_offer(data)
    Agent.new.offers.post(data)
  end

  def new_search(data)
    Agent.new.searches.post(data)
  end

  def update_offer(offer_id, data)
    Agent.new.offers.send(offer_id).put(data)
  end

  def update_search(search_id, data)
    Agent.new.searches.send(search_id).put(data)
  end

  def set_active_offer(offer_id, val)
    Agent.new.offers.send(offer_id).set_active.send(val ? "true" : "false").get
  end

  def set_active_search(search_id, val)
    Agent.new.searches.
      send(search_id).set_active.send(val ? "true" : "false").get
  end

  def update_search(search_id, data)
    Agent.new.searches.send(search_id).put(data)
  end

  def delete_offer(objid)
    Agent.new.offers.send(objid).delete
  end

  def delete_search(objid)
    Agent.new.searches.send(objid).delete
  end

  def object(objid)
    data = {
      :_id => objid
    }

    results = Agent.new.chat.byids.get(data.to_query)
    (results["searches"] + results["offers"]).flatten.first
  end

  def searches(sw, ne, not_owner, keywords = [])
    data = {
      :sw        => sw,
      :ne        => ne,
      :keywords  => keywords,
      :not_owner => not_owner,
      :is_active => "true",
    }

    _checkVersion(Agent.new.searches.get(data.to_query))
  end

  def searches_by_radius(center, radius, not_owner, keywords = [])
    data = {
      :center    => center,
      :radius    => radius,
      :keywords  => keywords,
      :not_owner => not_owner,
      :is_active => "true",
    }

    _checkVersion(Agent.new.searches.get(data.to_query))
  end

  def offers(sw, ne, not_owner, keywords = [])
    data = {
      :sw        => sw,
      :ne        => ne,
      :keywords  => keywords,
      :not_owner => not_owner,
      :is_active => "true",
    }

    _checkVersion(Agent.new.offers.get(data.to_query))
  end

  def offers_by_radius(center, radius, not_owner, keywords = [])
    data = {
      :center    => center,
      :radius    => radius,
      :keywords  => keywords,
      :not_owner => not_owner,
      :is_active => "true",
    }

    _checkVersion(Agent.new.offers.get(data.to_query))
  end

  def user_offers(sw, ne, owner, keywords = [])
    data = {
      :sw       => sw,
      :ne       => ne,
      :keywords => keywords,
      :owner    => owner,
    }

    _checkVersion(Agent.new.offers.get(data.to_query))
  end

  def user_searches(sw, ne, owner, keywords = [])
    data = {
      :sw       => sw,
      :ne       => ne,
      :keywords => keywords,
      :owner    => owner,
    }

    _checkVersion(Agent.new.searches.get(data.to_query))
  end

  def searches_by_keywords(keywords = [], not_owner = nil)
    data = {
      :keywords  => keywords,
      :is_active => "true",
    }
    data.merge!(:not_owner => not_owner) if not_owner

    _checkVersion(Agent.new.searches.get(data.to_query))
  end

  private

  def _checkVersion(data)
    raise "UnsupportedVersion: #{data["version"]}" if data["version"] != "1.0"
    data["data"]
  end
end
