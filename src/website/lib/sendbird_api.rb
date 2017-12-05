class SendbirdApi
  BaseUrl = "https://api.sendbird.com/v3/"
  Header = {
    "Api-Token"    => ENV['SENDBIRD_API_TOKEN'],
    "Content-Type" => "application/json, charset=utf8"
  }

  def initialize
    @actions = []
  end

  def method_missing(name, *args)
    @actions << name
    self
  end

  def get(params = "")
    JSON(RestClient.get(BaseUrl + @actions.join("/") + "?#{params}", Header))
  end

  def post(data)
    JSON(RestClient.post(BaseUrl + @actions.join("/"), data.to_json, Header))
  end

  def delete
    JSON(RestClient.delete(BaseUrl + @actions.join("/"), Header))
  end

  def _get_paginator(params, &block)
    token = ""
    while true
      params[:token] = token unless token.blank?
      get(params.to_query).tap do |data|
        yield data
        token = data["next"]
      end
      break if token.blank?
    end
  end
end
