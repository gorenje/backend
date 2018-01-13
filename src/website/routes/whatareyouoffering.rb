get '/' do
  if is_logged_in?
    # session contains an old user_id that no longer exists.
    session.delete(:user_id) unless User.where(:id=>session[:user_id]).exists?
  end
  tmpl_name = "index" + (is_logged_in? ? "_logged_in" : "")
  haml(:"whatareyouoffering/#{tmpl_name}",
         :layout => :"whatareyouoffering/layout")
end

get '/whatareyouoffering' do
  tmpl_name = "index" + (is_logged_in? ? "_logged_in" : "")
  haml( :"whatareyouoffering/#{tmpl_name}",
         :layout => :"whatareyouoffering/layout")
end

get '/javascript/init_whatareyouoffering.js' do
  content_type "application/javascript"

  file_name = "init" + (is_logged_in? ? "_logged_in" : "") + ".js"
  File.read(File.dirname(__FILE__) +
            "/../public/javascript/whatareyouoffering/" + file_name)
end

get '/whatareyouoffering/dialog' do
  return_json do
    i18n = TranslatorHelper.new("pages.whatareyouoffering.#{params[:f]}")
    {
      :title => i18n.title.t,
      :form => haml(:"whatareyouoffering/_dialog", :layout => false,
                    :locals => { :i18n => i18n })
    }
  end
end

post '/whatareyouoffering' do
  TrackerHelper.
    offer_preview({ :text      => params[:text],
                    :latitude  => session["latitude"],
                    :longitude => session["longitude"]
                  })

  tmpl_name = "_search_obj_resultslist" + (is_logged_in? ? "_logged_in" : "")
  keywords  = (params[:text]||"").downcase.split(/[[:space:]]+/)

  return_json do
    cnt = 0
    if is_logged_in?
      but_not_for_owner = User.find(session[:user_id]).userid_for_sendbird
      StoreHelper.searches_by_keywords(keywords, but_not_for_owner)
    else
      StoreHelper.searches_by_keywords(keywords)
    end.
      map do |hsh|
      hsh.tap do |h|
        clat = h["location"]["coordinates"][1]
        clng = h["location"]["coordinates"][0]

        h["json_location"] = { "lat" => clat, "lng" => clng }
        h["address"]       = place_to_address(h["place"])

        l1 = Geokit::LatLng.new(clat, clng)
        l2 = Geokit::LatLng.new(session["latitude"], session["longitude"])
        h["distance"] = l1.distance_to(l2).to_i

        h["ranking_num"]      = cnt+=1
        h["resultslist_html"] =
          haml(:"whatareyouoffering/#{tmpl_name}", :layout => false,
               :locals => hsh)
      end
    end.sort_by { |a| a["distance"] }
  end
end
