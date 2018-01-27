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

    def delete
      JSON(RestClient.delete(_base_url + @actions.join("/"), Header))
    end
  end

  def offers_for_owner(owner, sw, ne)
    data = sw && ne ? { :sw => sw, :ne => ne} : {}
    rslt = Agent.new.bulk.offers.send(owner).get(data.to_query)
    raise "UnsupportedVersion: #{rslt["version"]}" if rslt["version"] != "1.0"
    rslt["data"]
  end

  def object(objid)
    data = {
      :_id => objid
    }

    results = Agent.new.chat.byids.get(data.to_query)
    (results["searches"] + results["offers"]).flatten.first
  end
end
