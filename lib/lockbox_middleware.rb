require 'rubygems'
gem 'dnclabs-httparty'
require 'httparty'
require 'lockbox_cache'
require 'digest/md5'

class LockBox
  include HTTParty
  include LockBoxCache
  @@config = nil

  def self.config
    return @@config if @@config
    if defined?(Rails)
      root_dir = Rails.root
    else
      root_dir = '.'
    end
    yaml_config = YAML.load_file(File.join(root_dir,'config','lockbox.yml'))
    return_config = {}
    environment = Rails.env if defined? Rails
    environment ||= ENV['RACK_ENV']
    environment ||= 'test'
    if !environment.nil?
      if !yaml_config['all'].nil?
        $stderr.puts "The 'all' environment is deprecated in lockbox.yml; use built-in yaml convention instead."
        return_config = yaml_config['all']
        return_config.merge!(yaml_config[environment])
      else
        return_config = yaml_config[environment]
      end
    end
    @@config = return_config
  end

  base_uri config['base_uri']

  def initialize(app)
    @app = app
    @cache = LockBoxCache::Cache.new
  end

  def call(env)
    dup.call!(env)
  end
  
  def protected_paths
    self.class.config['protect_paths'].map do |path|
      Regexp.new(path)
    end
  end

  def call!(env)
    #attempt to authenticate any requests to /api
    request = Rack::Request.new(env)
    path_protected = false
    protected_paths.each do |path|
      if env['PATH_INFO'] =~ path
        path_protected = true
        authorized = false
        key = request['key']
        if key.blank?
          key = 'hmac'
        end
      
        auth = auth_response(key,env)
        authorized = auth[:authorized]
        auth_headers = auth[:headers]
      
        if authorized
          app_response = @app.call(env)
          app_headers = app_response[1]
          response_headers = app_headers.merge(auth_headers)
          return [app_response[0], response_headers, app_response[2]]
        else
          message = "Access Denied"
          return [401, {'Content-Type' => 'text/plain', 'Content-Length' => "#{message.length}"}, [message]]
        end
      end
    end
    unless path_protected
      #pass everything else straight through to app
      return @app.call(env)
    end
  end

  def auth_response(api_key, env={})
    if api_key != 'hmac'
      cached_auth = auth_cache(api_key)
      if !cached_auth.nil?
        # currently we don't cache forward headers
        return {:authorized => cached_auth, :headers => {}}
      end
    end
    auth_response = self.class.get("/authentication/#{api_key}", {:headers => auth_headers(env), :request => {:application_name => LockBox.config['application_name']}})
    authorized = (auth_response.code == 200)
    cache_response_if_allowed(api_key, auth_response) if authorized
    {:authorized => authorized, :headers => response_headers(auth_response)}
  end
  
  private
  
  def cache_response_if_allowed(api_key, auth_response)
    cache_control = auth_response.headers['Cache-Control'].split(/,\s*/)
    cache_max_age = 0
    cache_public = false
    cache_control.each do |c|
      if c =~ /^max-age=\s*(\d+)$/
        cache_max_age = $1.to_i
      elsif c == 'public'
        cache_public = true
      end
    end
    caching_allowed = (cache_max_age > 0 && cache_public)
    expiration = Time.at(Time.now.to_i + cache_max_age)
    cache_auth(api_key,expiration) if caching_allowed
  end

  def response_headers(auth_response)
    headers = {}
    auth_response.headers.each_pair do |h,v|
      if h =~ /^X-RateLimit-/
        headers[h] = v
      elsif h =~ /^X-LockBox-/
        headers[h] = v
      end
    end
    headers
  end

  def auth_headers(env)
    headers = {}
    headers['Referer'] = "#{env['rack.url_scheme']}://#{env['SERVER_NAME']}#{env['PATH_INFO']}"
    headers['Referer'] << "?#{env['QUERY_STRING']}" unless env['QUERY_STRING'].blank?
    headers['X-Referer-Content-MD5'] = Digest::MD5.hexdigest(Rack::Request.new(env).body.read) if env['CONTENT_TYPE']
    {'Content-Type' => 'CONTENT_TYPE', 'Date' => 'HTTP_DATE', 'Method' => 'REQUEST_METHOD',
     'Authorization' => 'HTTP_AUTHORIZATION'}.each_pair do |h,e|
      headers["X-Referer-#{h}"] = env[e] unless env[e].blank?
    end
    headers["X-Referer-Date"] = env['HTTP_X_AUTHHMAC_REQUEST_DATE'] unless env['HTTP_X_AUTHHMAC_REQUEST_DATE'].blank?
    headers
  end
  
  def cache_key(api_key)
    "lockbox_#{api_key}"
  end

  def auth_cache(api_key)
    expiration = @cache.read(cache_key(api_key))
    return nil if expiration.nil?
    expiration = Time.at(expiration)
    if expiration <= Time.now
      @cache.delete(cache_key(api_key))
      nil
    elsif expiration > Time.now
      true
    end
  end

  def cache_auth(api_key,expiration)
    @cache.write(cache_key(api_key),expiration.to_i)
  end

end
