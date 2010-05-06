require 'httparty'

class LockBox  
  include HTTParty
  base_uri 'http://localhost:3001'

  def initialize(app)
    @app = app
  end

  def call(env)
    dup.call!(env)
  end

  def call!(env)
    #attempt to authenticate any requests to /api
    request = Rack::Request.new(env)
    if env['PATH_INFO'] =~ /^\/api\/[^\/]+/i
      authorized = false
      key = request['key']
      if key.blank?
        key = 'hmac'
      end
      authorized = auth?(key,env)
      
      if authorized
        return @app.call(env)
      else
        message = "Access Denied"
        return [401, {'Content-Type' => 'text/plain', 'Content-Length' => "#{message.length}"}, message]
      end
    else
      #pass everything else straight through to app
      return @app.call(env)
    end
  end

  def auth?(api_key, env={})
    headers = prepare_forwarded_headers(env)
    options = {:headers => headers}
    return (self.class.get("/authentication/#{api_key}", options).code == 200)
  end

  def prepare_forwarded_headers(env)
    headers = {}
    headers['Referer'] = "#{env['rack.url_scheme']}://#{env['SERVER_NAME']}#{env['PATH_INFO']}"
    headers['Referer'] << "?#{env['QUERY_STRING']}" unless env['QUERY_STRING'].blank?
    {'Content-Type' => 'Content-Type', 'Content-MD5' => 'Content-MD5', 'Date' => 'HTTP_DATE', 'Method' => 'REQUEST_METHOD', 'Authorization' => 'HTTP_AUTHORIZATION'}.each_pair do |h,e|
      headers["X-Referer-#{h}"] = env[e] unless env[e].blank?
    end
    headers
  end

end