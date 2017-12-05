MenuItems = {
  "searches" => ["/searches", "search2"],
  "offers" => ["/user/offers", "tag8"]
}

ImageSize = {
  :width => 60,
  :height => 60
}

InitialCircleRadiusMeters = 500

CdnHosts = (ENV['CDN_HOSTS'] || "").split(",")
