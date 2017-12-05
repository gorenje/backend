namespace :ebay do
  desc <<-EOF
    Get access token.
  EOF
  task :access_token => :environment do
    base_host = "https://api.ebay.com"

    auth = Base64.encode64("#{ENV['EBAY_APP_ID']}:#{ENV['EBAY_CRT_ID']}").
      gsub(/\n/, '')
    headers = {
      "Content-Type"  => "application/x-www-form-urlencoded",
      "Authorization" => "Basic #{auth}",
      "X-EBAY-SOA-GLOBAL-ID"    => "EBAY-DE"
    }

    data = {
      "grant_type"   => "client_credentials",
      "redirect_url" => ENV['EBAY_RUNAME'],
      "scope"        => "https://api.ebay.com/oauth/api_scope"
    }
    url = "#{base_host}/identity/v1/oauth2/token"
    access_token = JSON(RestClient.post(url,data.to_query,
                                        headers).body)["access_token"]

    url = "#{base_host}/buy/browse/v1/item_summary/search"
    headers = {
      "Authorization"           => "Bearer #{access_token}",
      "X-EBAY-C-ENDUSERCTX"     => "contextualLocation=country=DE,zip=10117",
      "X-EBAY-SOA-GLOBAL-ID"    => "EBAY-DE"
    }
    data = {
      "GLOBAL-ID" => "EBAY-DE",
      "category_ids" => 108765,
      "q"            => "Fussballschuhe",
      "filter"       => "pickupRadiusUnit:km,pickupRadius:20,excludeSellers:{hemhofen|christiane_strand3},pickupCountry:DE,sellerAccountTypes:{INDIVIDUAL},pickupPostalCode:10117,conditions:{USED},deliveryOptions:{SELLER_ARRANGED_LOCAL_PICKUP}",
      "limit"        => 10,
    }

    RestClient.log = 'stdout'
    puts(url+"?"+data.to_query)
    puts RestClient.get(url+"?"+data.to_query + "&GLOBAL-ID=EBAY-DE", headers)
  end

  desc <<-EOF
    Do search using website
  EOF
  task :search, [:search_id] => :environment do |t,args|
    obj = StoreHelper.object(args.search_id)



    agent = MechanizeHelper.agent
    page = agent.get("https://www.ebay-kleinanzeigen.de/s-10117/donuts/k0l3520r1")


    item.search("[data-adid]").attr("data-adid").value
  end
end
