module ViewHelpers
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
