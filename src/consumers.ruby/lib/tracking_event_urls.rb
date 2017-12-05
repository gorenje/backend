module Tracking
  class Event
    DefaultOptions = {
      :host => $hosthandler.tracking.url
    }

    def initialize
    end

    def conversion(params, options = {})
      generate_url("/t/mac", params, options)
    end

    def install(params, options = {})
      generate_url("/t/ist", params, options)
    end

    def postback(params, options = {})
      generate_url("/t/pob", params, options)
    end

    private

    def params_to_query(params)
      uri = Addressable::URI.new
      uri.query_values = params
      uri.query
    end

    def generate_url(path, params, options)
      opts = DefaultOptions.merge(options)
      { :url    => "%s%s?%s" % [opts[:host], path, params_to_query(params)],
        :body   => nil,
        :header => {}
      }
    end
  end
end
