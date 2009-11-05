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
    if env['PATH_INFO'] =~ /^\/api\/([^\/]+)\//i
      if auth?($1)
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

  def auth?(api_key)
    return (self.class.get("/authentication/#{api_key}").code == 200)
  end


end