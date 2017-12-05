get '/api/offers.json' do
  return_json do
    cnt = 0
    if params[:id]
      [StoreHelper.object(params[:id])]
    else
      @user = User.find(session[:user_id])
      owner = @user.userid_for_sendbird
      StoreHelper.
        offers(params[:sw], params[:ne], owner,
                 (params[:keywords]||"").downcase.split(/[[:space:]]+/))
    end.map do |hsh|
      hsh.tap do |h|
        clat = h["location"]["coordinates"][1]
        clng = h["location"]["coordinates"][0]
        latDelta = h["location"]["dimension"]["latitudeDelta"]
        lngDelta = h["location"]["dimension"]["longitudeDelta"]

        h["json_location"] = { "lat" => clat, "lng" => clng }
        h["latDelta"]      = latDelta
        h["lngDelta"]      = lngDelta
        h["address"]       = place_to_address(h["location"]["place"])

        l1 = Geokit::LatLng.new(clat - latDelta, clng - lngDelta)
        l2 = Geokit::LatLng.new(clat + latDelta, clng + lngDelta)
        h["radius"] = (l1.distance_to(l2) / 2.0).to_i

        h["ranking_num"]      = cnt+=1
        h["marker_icon"]      = "/images/marker/#{h["ranking_num"]}.svg"
        h["marker_icon_highlight"] =
          "/images/marker/#{h["ranking_num"]}.svg?c=%23444"

        h["i18n"] = TranslatorHelper.new("partials.offer_obj_resultslist")
        h["resultslist_html"] =
          haml(:"_resultslist_entry", :layout => false, :locals => hsh)
      end
    end.sort_by { |a| a["ranking_num"] }
  end
end
