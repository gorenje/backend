class AuthFilter
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    # server public stuff
    if request.path_info =~ /^\/(js|css|img|images|fonts)/
      return @app.call(env)
    end

    unless request.session[:authenticated]
      unless (['/accessdenied', '/auth', '/oauth2callback', '/api/1/create',
               '/pingdom', '/api/1/delete'].
              include?(request.path_info) || request.path_info =~ /^\/auth/ ||
              request.path_info =~ /\/\.well-known\/acme-challenge\//)
        url = request.scheme + "://" + request.host_with_port + "/auth"
        return [ 307, { 'Location' => url }, []]
      end
    end

    return @app.call(env)
  end
end
