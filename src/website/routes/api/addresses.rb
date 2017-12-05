get '/api/addresses' do
  cnt = 0
  return_json do
    User.find(session[:user_id]).addresses.sort_by(&:name).map do |addr|
      { }.tap do |h|
        h["json_location"] = { "lat" => addr.latitude, "lng" => addr.longitude }
        h["bounds"] = {
          "sw" => JSON(addr.bounds["sw"]),
          "ne" => JSON(addr.bounds["ne"]),
        }

        h["radius"]      = addr.radius_in_meters
        h["ranking_num"] = cnt+=1
        h["marker_icon"] = "/images/marker/#{h["ranking_num"]}.svg"

        h["marker_icon_highlight"] =
          "/images/marker/#{h["ranking_num"]}.svg?c=%23444"
        h["resultslist_html"] =
          haml(:"_user_address_resultslist", :layout => false,
               :locals => h.merge(JSON(addr.to_json)))
      end
    end
  end
end

get '/api/address/:id/delete' do
  return_json do
    User.find(session[:user_id]).
      addresses.where(:id => params[:id]).first.try(:destroy)
    { :status => :ok }
  end
end

post '/api/address/:id/update' do
  return_json do
    @user = User.find(session[:user_id])

    addr = Address.where(:id => params[:id], :user => @user).first

    if addr
      set_radius(params) if params[:radius].blank?
      addr.update_from_params(params)
    end

    { :status => :ok }
  end
end

post '/api/address/create' do
  return_json do
    @user = User.find(session[:user_id])

    params[:name] = "- No Name -" if params[:name].blank?

    addr = Address.where(:name => params[:name], :user => @user).first ||
             Address.create(:name => params[:name], :user => @user)

    set_radius(params) if params[:radius].blank?
    addr.update_from_params(params)

    { :status => :ok }
  end
end
