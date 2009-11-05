require 'httparty'

class LockBox
  include HTTParty
  base_uri 'http://localhost:3000'

  def initialize(app)
    @app = app
  end

  def call(env)
    dup.call!(env)
  end

  def call!(env)
    #attempt to authenticate any requests to /api
    if env['PATH_INFO'] =~ /^\/api/i
      if auth?(env)
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

  def auth?(env)
    request = Rack::Request.new(env)
    token = request.params['token']
    return (self.class.get("/authenticate?token=#{token}").code == 200)
  end


end