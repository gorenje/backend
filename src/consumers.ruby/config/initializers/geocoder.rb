require 'geocoder'

Geocoder.
  configure(
    :units => :km,
    :timeout => 5,
    :lookup => :google,
    :use_https => true,
    :google => {
      :api_key => ENV['GOOGLE_API_KEY'],
    }
  )
