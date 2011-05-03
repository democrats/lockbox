require 'rubygems'
require 'httpotato'
require 'lockbox_cache'
require 'hmac_request'
require 'statsd'

class LockBox
  include HTTPotato
  include LockBoxCache

  attr_accessor :cache

  @@config = nil
  @@protected_paths = nil

  def self.config
    return @@config if @@config
    #use rails config if it's there
    if defined?(Rails) && Rails.root
      config_file = Rails.root.join('config','lockbox.yml')
      @@config = YAML.load_file(config_file)[Rails.env]
    else
      env = ENV['RACK_ENV'] || "test"
      config_file = File.join(Dir.pwd, 'config','lockbox.yml')
      all_configs = YAML.load_file(config_file)
      if !all_configs['all'].nil?
        $stderr.puts "The 'all' environment is deprecated in lockbox.yml; use built-in yaml convention instead."
        @@config = all_configs['all'].merge!(all_configs[env])
      else
        @@config = all_configs[env]
      end
    end
    return @@config
  end

  base_uri config['base_uri']

  def initialize(app)
    @app = app
    @cache = LockBoxCache::Cache.new
    @graphite = setup_graphite
  end

  def call(env)
    time_it("call") { dup.call!(env) }
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
        request = HmacRequest.new_from_rack_env(env)
        if !request['key'].nil?
          auth_type = 'key'
          auth = auth_via_key(request['key'], request)
        else
          auth_type = 'hmac'
          auth = auth_via_hmac(request)
        end

        if auth[:authorized]
          record_it("#{auth_type}.authorized")
          app_response = @app.call(env)
          return [app_response[0], app_response[1].merge(auth[:headers]), app_response[2]]
        else
          record_it("#{auth_type}.denied")
          message = "Access Denied"
          return [401, {'Content-Type' => 'text/plain', 'Content-Length' => "#{message.length}"}, [message]]
        end
    else
      #pass everything else straight through to app
      record_it("unprotected")
      return @app.call(env)
    end
  end

  def auth_via_key(api_key, request)
    cached_auth = check_key_cache(api_key)
    # currently we don't cache forward headers
    return {:authorized => cached_auth, :headers => {}} if cached_auth

    auth_response = time_it("key.http_request") { 
      self.class.get("/authentication/#{api_key}", {:headers => request.get_xreferer_auth_headers, :request => {:application_name => LockBox.config['application_name']}})
    }

    authorized = (auth_response.code == 200)
    cache_key_response_if_allowed(api_key, auth_response) if authorized
    {:authorized => authorized, :headers => response_headers(auth_response)}
  end

  def auth_via_hmac(hmac_request)
    cached_auth = check_hmac_cache(hmac_request)
    return {:authorized => cached_auth, :headers => {}} if cached_auth

    auth_response = time_it("hmac.http_request") {
      self.class.get("/authentication/hmac", {:headers => hmac_request.get_xreferer_auth_headers, :request => {:application_name => LockBox.config['application_name']}})
    }

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
    if caching_allowed
      time_it("key.cache_write") { @cache.write(cache_string_for_key(api_key), expiration.to_i) }
    end
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
      time_it("hmac.cache_write") { @cache.write(cache_string_for_hmac(hmac_request.hmac_id), [api_key, expiration.to_i]) }
    end
  end

  def response_headers(auth_response)
    headers = {}
    auth_response.headers.each_pair do |h,v|
      headers[h] = v if h =~ /^X-RateLimit-|^X-LockBox-/
    end
    headers
  end

  def check_key_cache(api_key)
    expiration = time_it("key.cache_read") { @cache.read(cache_string_for_key(api_key)) }
    return nil if expiration.nil?
    expiration = Time.at(expiration)
    if expiration <= Time.now
      record_it("key.cache_expired")
      @cache.delete(cache_string_for_key(api_key))
      nil
    else
      record_it("key.cache_hit")
      true
    end
  end

  def check_hmac_cache(hmac_request)
    hmac_id, hmac_hash = hmac_request.hmac_id, hmac_request.hmac_hash
    return nil if hmac_id.nil? || hmac_hash.nil?
    cached_val = time_it("hmac.cache_read") { @cache.read(cache_string_for_hmac(hmac_id)) }
    return nil if cached_val.nil?
    key, expiration = cached_val
    expiration = Time.at(expiration)
    if expiration <= Time.now
      record_it("hmac.cache_expired")
      @cache.delete(cache_string_for_hmac(hmac_id))
      nil
    else
      #as long as the request is signed correctly, no need to contact the lockbox server to verify
      #just see if the request is signed properly and let it through if it is
      if hmac_request.hmac_auth({hmac_id => key}) == key
        record_it("hmac.cache_hit")
        return true
      else
        return nil
      end
    end
  end

  def graphite_path
    self.class.config["graphite_path"]
  end
  def setup_graphite
    return nil unless ( self.class.config.has_key?("statsd_host") && 
                        self.class.config.has_key?("statsd_port") && 
                        self.class.config.has_key?("graphite_path") )
    Statsd.host = self.class.config["statsd_host"]
    Statsd.port = self.class.config["statsd_port"]
    Statsd
  end

  def record_it(data_path)
    Statsd.increment("#{graphite_path}.#{data_path}") if @graphite
  end

  def time_it(data_path)
    start_ts = Time.now
    rv = yield

    if @graphite
      #puts "Calling #timing with #{graphite_path}.#{data_path}"
      Statsd.timing( "#{graphite_path}.#{data_path}", (Time.now - start_ts) * 1000 )
    end

    rv
  end
end
