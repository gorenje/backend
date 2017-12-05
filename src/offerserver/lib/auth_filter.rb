class AuthFilter
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    unless request.session[:authenticated] ||
        request.path_info =~ /^\/(auth|pingdom)/ ||
        request.path_info =~ /\/\.well-known\/acme-challenge\//
      request.session[:lgkp] = request.path
      url = request.scheme + "://" + request.host_with_port + "/auth/google_oauth2"
      return [ 307, { 'Location' => url }, []]
    end
    return @app.call(env)
  end
end
