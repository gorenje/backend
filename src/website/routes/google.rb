get '/javascript/google.js' do
  content_type "application/javascript"
  mechanize_agent.
    get("https://maps.googleapis.com/maps/api/js?key="+
        "#{ENV['GOOGLE_API_KEY']}&callback=initMap").body
end
