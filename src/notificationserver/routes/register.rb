post '/register' do
  protected!
  orig_params = params.clone

  params = if request.env['CONTENT_TYPE'] =~ /application\/json/
             request.body.rewind  # back to the head, if needed
             JSON(request.body.read)
           else
             orig_params
           end

  puts "---------------------"
  puts params
  puts "---------------------"
  puts orig_params
  puts "---------------------"

  if params["device_id"]
    details = {}.tap do |h|
      ["onesignal_id", "sendbird_id", "locale", "callback_url"].each do |attr|
        h[attr] = params[attr] unless params[attr].blank?
      end
    end

    Mapping.
      where(:device_id => params["device_id"]).
      first_or_create.
      update(details)
  end

  if params[:redirect]
    redirect "/mappings"
  else
    return_json do
      { :status => :ok }
    end
  end
end

get '/register' do
  protected!
  haml :register
end
