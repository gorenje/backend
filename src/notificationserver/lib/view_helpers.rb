module ViewHelpers
  def redirect_host_to_ssl?
    request.scheme == 'http' &&
      !ENV['HOSTS_WITH_NO_SSL'].split(",").map(&:strip).include?(request.host)
  end

  def redirect_host_to_www?
    !(request.host =~ /^www[.]/) &&
      !ENV['HOSTS_WITH_NO_SSL'].split(",").map(&:strip).include?(request.host)
  end

  def return_json
    content_type :json
    yield.to_json
  end

  def if_blank(val, text = "- None -")
    val.blank? ? "<span class='empty'>#{text}</span>" : val
  end

  def get_json_params
    orig_params = params.clone

    if request.env['CONTENT_TYPE'] =~ /application\/json/
      request.body.rewind  # back to the head, if needed
      JSON(request.body.read)
    else
      orig_params
    end
  end
end
