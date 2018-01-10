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
      query = params.empty? ? "" : "?#{params}"
      JSON(RestClient.get(_base_url + @actions.join("/") + query, Header))
    end

    def post(data)
      JSON(RestClient.post(_base_url + @actions.join("/"), data.to_json,Header))
    end

    def delete
      JSON(RestClient.delete(_base_url + @actions.join("/"), Header))
    end
  end
end
