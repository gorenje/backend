# coding: utf-8
module ViewHelpers
  def return_json
    content_type :json
    yield.to_json
  end

  def must_be_logged_in
    redirect '/whatareyouoffering' unless is_logged_in?
  end

  def view_exist?(path)
    File.exists?(File.dirname(__FILE__) + "/../views/#{path}.haml")
  end

  def is_logged_in?
    !!session[:user_id]
  end

  def render_as_haml(txt)
    Haml::Engine.new(txt).render
  end

  def cdn_host
    (host = CdnHosts.sample).nil? ? "" : "//#{host}"
  end

  def icon(name)
    { "data-icon" => name, :style => "font-size: 20px;" }
  end

  def icon18(name)
    { "data-icon" => name, :style => "font-size: 18px;" }
  end

  def if_user_is_owner(objid)
    user = User.find(session[:user_id])
    obj  = StoreHelper.object(objid)

    yield(user) if obj["owner"] == user.userid_for_sendbird
  end

  def format_rating_value(val)
    return "-" if val.nil?
    val.is_a?(Integer) ? val : "%02.2f" % val
  end

  def format_date(dt)
    dt.to_s
  end

  def path_replace_account_id(new_account)
    request.path_info.sub(/#{@account.id}/, "#{new_account.id}")
  end

  def to_email_confirm(s)
    "#{$hosthandler.login.url}/users/email-confirmation?r=#{s}"
  end

  def params_blank?(*args)
    args.any? { |a| params[a].blank? }
  end

  def generate_svg(name, &block)
    content_type "image/svg+xml"
    yield if block_given?
    haml :"images/_#{name}.svg", :layout => false
  end

  def extract_email_and_salt(encstr)
    estr = begin
             AdtekioUtilities::Encrypt.decode_from_base64(encstr)
           rescue
             begin
               AdtekioUtilities::Encrypt.
                 decode_from_base64(CGI.unescape(encstr))
             rescue
               "{}"
             end
           end
    # this is a hash: { :email => "fib@fna.de", :salt => "sddsdad" }
    # so sorting and taking the last will give: ["fib@fna.de","sddsdad"]
    JSON.parse(estr).sort.map(&:last) rescue [nil,nil]
  end

  def place_to_address(place)
    return nil if place.blank? ||  place.keys.empty?
    details = place[place.keys.first]
    return nil if details.blank?
    "%s %s, %s, %s" % ["route", "street_number", "locality", "country"].
                        map { |a| details[a] }
  end

  def page_can_be_viewed_while_not_logged_in
    ['/', '/auth', '/logout', '/aboutus', '/contact', '/login', '/register',
     '/users/email-confirmation', '/user/emailconfirm', '/whatareyouoffering',
     '/user/location', '/whatareyouoffering/dialog',
     '/javascript/init_whatareyouoffering.js', '/javascript/google.js'
    ].include?(request.path_info) ||
      case request.path_info
      when /^\/profile\/.+/ then request.get?
      when /^\/notification\/.+/ then request.post?
      when /^\/resend\/email\/.+/ then true
      when /^\/images\/.+/ then true
      else
        false
      end
  end

  def set_radius(params)
    l1 = Geokit::LatLng.new(params[:sw]["latitude"].to_f,
                            params[:sw]["longitude"].to_f)
    l2 = Geokit::LatLng.new(params[:ne]["latitude"].to_f,
                            params[:ne]["longitude"].to_f)
    params[:radius] = (l1.distance_to(l2) / 2.0).to_i
  end

  def mechanize_agent(user_agent = :use_mozilla)
    Mechanize.new.tap do |agent|
      agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      if user_agent == :use_mozilla
        agent.user_agent_alias = 'Linux Mozilla'
      else
        agent.user_agent = user_agent
      end
    end
  end

  def fill_hash(h, cnt)
    clat = h["location"]["coordinates"][1]
    clng = h["location"]["coordinates"][0]

    h["json_location"] = { "lat" => clat, "lng" => clng }
    h["address"]       = place_to_address(h["place"])
    h["radius"]        = h["radiusMeters"].to_i
    h["ranking_num"]   = cnt
    h["marker_icon"]   = "/images/marker/#{h["ranking_num"]}.svg"
    h["marker_icon_highlight"] =
      "/images/marker/#{h["ranking_num"]}.svg?c=%23444"
  end

  def generate_subject_from_params(user)
    owner = user.userid_for_sendbird

    images = if params[:file]
               [].tap do |container|
                 params["file"].keys.each do |idx|
                   container <<
                     ImageHelper.upload_file(params["file"][idx]["tempfile"])
                 end
               end.compact
             else
               []
             end

    hsh = {
      :owner         => owner,
      :text          => params[:text],
      :keywords      => params[:text].downcase.split(/[[:space:]]+/),
      :validfrom     => Time.now.utc.strftime("%s%L").to_i,
      :validuntil    => (Date.today + 1000).to_time.utc.strftime("%s%L").to_i,
      :isMobile      => false,
      :allowContacts => true,
      :showLocation  => true,
      :images        => images,
      :extdata       => {},
      :radiusMeters  => params[:radius],
      :location => {
        :type        => "Point",
        :coordinates => [ params[:longitude].to_f, params[:latitude].to_f ],
      }
    }

    unless params[:address].empty?
      # address is assumed to be of the format:
      #     Veteranenstraße 21, 10119 Berlin, Germany
      # i.e. street_name street_number, postal_code city_name, country

      street, city_details, country = params[:address].split(/,/).map(&:strip)
      street_number, city_name, postal_code = [nil]*4

      if street =~ /(.+) ([0-9\/\-–]+)$/
        street        = $1.strip
        street_number = $2
      end

      if city_details =~ /(.+) (.+)/
        city_name   = $2
        postal_code = $1
      end

      hsh[:place] = {
        :en => {
          :locality                    => city_name     || city_details,
          :street_number               => street_number || "",
          :administrative_area_level_1 => city_name     || city_details,
          :postal_code                 => postal_code   || "",
          :country                     => country,
          :route                       => street,
        }
      }
    end

    hsh
  end
end
