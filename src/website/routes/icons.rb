if ENV['RACK_ENV'] == "development"
  get '/icons/preview' do
    haml :icons
  end
end
