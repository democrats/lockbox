require 'rubygems'
require 'httpotato'
gem 'dnclabs-auth-hmac'
require 'auth-hmac'
require 'lockbox_cache'
require 'hmac_request'
require 'digest/md5'

class LockBox
  include HTTPotato
  include LockBoxCache
  
  @@config = nil
  @@protected_paths = nil
  
  attr_accessor :cache

  def self.config
    return @@config if @@config
    #use rails config if it's there
    if defined?(Rails)
      config_file = Rails.root.join('config','lockbox.yml')
      @@config = YAML.load_file(config_file)[Rails.env]
    else
      env = ENV['RACK_ENV'] || "test"
      config_file = File.join(File.dirname(__FILE__), 'config', 'lockbox.yml')
      all_configs =YAML.load_file(config_file)
      if !all_configs['all'].nil?
        @@config = all_configs['all'].merge!(all_configs[env])
        $stderr.puts "The 'all' environment is deprecated in lockbox.yml; use built-in yaml convention instead."
      else
        @@config = all_configs[env]
      end
    end
  end

  base_uri config['base_uri']

  def initialize(app)
    @app = app
    @cache = LockBoxCache::Cache.new
  end

  def call(env)
    dup.call!(env)
  end
  
  def cache_string_for_key(api_key)
    "lockbox_key_#{api_key}"
  end
  
  def cache_string_for_hmac(hmac_id)
    "lockbox_hmac_#{hmac_id.gsub(/[^a-z0-9]/i,'_')}"
  end
  
  def protected_paths
    @@protect_paths ||= self.class.config['protect_paths'].map{ |path| Regexp.new(path) }
  end

  def call!(env)
    protected_path = protected_paths.detect{|path| env['PATH_INFO'] =~ path}
    #if the requested path is protected, it needs to be authenticated
    if protected_path
        request = Rack::Request.new(env)
        if request['key'].present?
          auth = auth_via_key(request['key'], env)
        else
          auth = auth_via_hmac(env)
        end
      
        if auth[:authorized]
          app_response = @app.call(env)
          return [app_response[0], app_response[1].merge(auth[:headers]), app_response[2]]
        else
          message = "Access Denied"
          return [401, {'Content-Type' => 'text/plain', 'Content-Length' => "#{message.length}"}, [message]]
        end
    else
      #pass everything else straight through to app
      return @app.call(env)
    end
  end

  def auth_via_key(api_key, env={})
    cached_auth = check_key_cache(api_key)
    # currently we don't cache forward headers
    return {:authorized => cached_auth, :headers => {}} unless cached_auth.nil?
    auth_response = self.class.get("/authentication/#{api_key}", {:headers => get_auth_headers(env), :request => {:application_name => LockBox.config['application_name']}})
    authorized = (auth_response.code == 200)
    cache_key_response_if_allowed(api_key, auth_response) if authorized
    {:authorized => authorized, :headers => response_headers(auth_response)}
  end
  
  def auth_via_hmac(env={})
    hmac_request = HmacRequest.new(env)
    cached_auth = check_hmac_cache(hmac_request)
    if cached_auth
      return {:authorized => cached_auth, :headers => {}}
    end
    auth_response = self.class.get("/authentication/hmac", {:headers => get_auth_headers(env), :request => {:application_name => LockBox.config['application_name']}})
    authorized = (auth_response.code == 200)
    cache_hmac_response_if_allowed(hmac_request, auth_response) if authorized
    {:authorized => authorized, :headers => response_headers(auth_response)}
  end
  
  private
  
  def cache_key_response_if_allowed(api_key, auth_response)
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
    @cache.write(cache_string_for_key(api_key), expiration.to_i) if caching_allowed
  end
  
  def cache_hmac_response_if_allowed(hmac_request, auth_response)
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
    if caching_allowed
      api_key = auth_response.headers['X-LockBox-API-Key']
      @cache.write(cache_string_for_hmac(hmac_request.hmac_id), [api_key, expiration.to_i])
    end
  end

  def response_headers(auth_response)
    headers = {}
    auth_response.headers.each_pair do |h,v|
      headers[h] = v if h =~ /^X-RateLimit-|^X-LockBox-/
    end
    headers
  end

  #these are the X-Referer-Headers that get passed along to lockbox.dnc.org
  def get_auth_headers(env)
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
  


  def check_key_cache(api_key)
    expiration = @cache.read(cache_string_for_key(api_key))
    return nil if expiration.nil?
    expiration = Time.at(expiration)
    if expiration <= Time.now
      @cache.delete(cache_string_for_key(api_key))
      nil
    else
      true
    end
  end
  
  def check_hmac_cache(hmac_request)
    hmac_id, hmac_hash = hmac_request.hmac_id, hmac_request.hmac_hash
    return nil if hmac_id.nil? || hmac_hash.nil?
    cached_val = @cache.read(cache_string_for_hmac(hmac_id))  
    return nil if cached_val.nil?
    key, expiration = cached_val
    expiration = Time.at(expiration)
    if expiration <= Time.now
      @cache.delete(cache_string_for_hmac(hmac_id))
      nil
    else
      #as long as the request is signed correctly, no need to contact the lockbox server to verify
      #just see if the request is signed properly and let it through if it is
      authhmac = AuthHMAC.new(hmac_id => key)
      return true if authhmac.authenticated?(hmac_request)
      return nil
    end
  end
  
end
