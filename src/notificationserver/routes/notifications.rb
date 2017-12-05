get '/notification/:deviceid' do
  @deviceid = params[:deviceid]
  haml :create_notification
end

post '/notification' do
  notification = case params[:type]
            when "freeform"
              if params[:url] && params[:msg]
                PushHelper.new_notification(params[:url], params[:msg])
              end
            end

  @result = if notification
              Mapping.where(:device_id => params[:deviceid]).compact.
                map { |m| m.fire_push(notification) }
            else
              "Failed"
            end

  haml :result
end

post '/notify' do
  return_json do
    params = get_json_params

    case params["category"]
    when "match_found"
      srch = OpenStruct.new(params['search'])
      offr = OpenStruct.new(params['offer'])

      searcher_notification = PushHelper.open_search(srch,offr)
      offerer_notification  = PushHelper.open_offer(offr,srch)

      RedisHelper.rate_limit_offer(offr, srch) do
        Mapping.where(:device_id => offr.device_id).compact.
          each do |mapping|
          mapping.fire_push(offerer_notification)
        end
      end

      RedisHelper.rate_limit_search(srch, offr) do
        Mapping.where(:device_id => srch.device_id).compact.
          each do |mapping|
          mapping.fire_push(searcher_notification)
        end
      end
    end

    TrackerHelper.match_found(offr, srch)
    puts params
    { :status => :ok}
  end
end
