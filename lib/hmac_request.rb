require 'rubygems'
gem 'dnclabs-auth-hmac'
require 'auth-hmac'
require 'digest/md5'

class HmacRequest
  attr_accessor :request, :env, :body, :hmac_id, :hmac_hash
  undef :method

  @@valid_date_window = 600 # seconds

  HTTP_HEADER_TO_ENV_MAP = { 'Content-Type'  => 'CONTENT_TYPE',
                             'Content-MD5'   => 'CONTENT_MD5',
                             'Date'          => 'HTTP_DATE',
                             'Method'        => 'REQUEST_METHOD',
                             'Authorization' => 'HTTP_AUTHORIZATION' }

  def self.new_from_rack_env(env)
    r = self.new(env)
    return r
  end

  def self.new_from_rails_request(request)
    r = self.new(request.headers)
    #pull stuff out of X-Referer, which is where the middleware sticks it
    HTTP_HEADER_TO_ENV_MAP.each_pair do |h,e|
      r.env[e] = r.env["X-Referer-#{h}"] unless r.env["X-Referer-#{h}"].blank?
    end

    return r
  end

  def initialize(env)
    @request = Rack::Request.new(env)
    @env = @request.env
    @body = @request.body if has_body?(@env['REQUEST_METHOD'])
  end

  def [](key)
    @request[key]
  end

  def path
    #use Referer if it's there, which it will be when this gets called while hitting the AuthenticationController
    if @env['Referer'].to_s =~ /^(?:http:\/\/)?[^\/]*(\/.*)$/
      return $1
    end
    #if we're in the middleware, it won't be there but we can use the request's path to the same effect
    return @request.path
  end

  def has_body?(method)
    ["PUT","POST"].include?(method)
  end

  def hmac_id
    get_hmac_vals if @hmac_id.nil?
    @hmac_id
  end

  def hmac_hash
    get_hmac_vals if @hmac_hash.nil?
    @hmac_hash
  end

  def get_hmac_vals
    @env['HTTP_AUTHORIZATION'].to_s =~ /^AuthHMAC ([^:]+):(.*)$/
    @hmac_id = $1
    @hmac_hash = $2
  end


  def hmac_auth(credential_store)
    authhmac = AuthHMAC.new(credential_store)
    if authhmac.authenticated?(self) && (@env['HTTP_DATE'].blank? || self.date_is_recent? )
      credential_store[self.hmac_id]
    else
      log_auth_error(credential_store[self.hmac_id])
      return false
    end
  end

  def date_is_recent?()
    req_date = nil

    begin
      req_date = Time.httpdate(@env['HTTP_DATE'])
    rescue Exception => ex
      if ex.message =~ /not RFC 2616 compliant/
        # try rfc2822
        req_date = Time.rfc2822(@env['HTTP_DATE'])
      else
        raise ex
      end
    end

    if Time.now.to_i - req_date.to_i >= @@valid_date_window
      log "Request date #{req_date} is more than #{@@valid_date_window} seconds old"
      return false
    else
      return true
    end
  end

  #these are the X-Referer-Headers that get passed along to lockbox from the middleware for authentication
  def get_xreferer_auth_headers()
    headers = {}
    headers['Referer'] = "#{@env['rack.url_scheme']}://#{@env['SERVER_NAME']}#{@env['PATH_INFO']}"
    headers['Referer'] << "?#{@env['QUERY_STRING']}" unless @env['QUERY_STRING'].blank?
    HTTP_HEADER_TO_ENV_MAP.each_pair do |h,e|
      headers["X-Referer-#{h}"] = @env[e] unless @env[e].blank?
    end
    headers['X-Referer-Content-MD5'] = Digest::MD5.hexdigest(@request.body.read) if @env['CONTENT_TYPE']
    headers["X-Referer-Date"] = @env['HTTP_X_AUTHHMAC_REQUEST_DATE'] unless @env['HTTP_X_AUTHHMAC_REQUEST_DATE'].blank?
    headers
  end

  def log_auth_error(key)
    log "Logging Lockbox HMAC authorization error:"
    log "Path: #{self.path}"

    HTTP_HEADER_TO_ENV_MAP.values.each do |header|
      log "#{header}: #{@env[header]}"
    end

    log "HMAC Canonical String: #{ AuthHMAC::CanonicalString.new(self).inspect}"

    if self.hmac_id.nil?
      log("HMAC failed because request is not signed")
    elsif key
      log("HMAC failed - expected #{AuthHMAC.signature(self,key)} but was #{self.hmac_hash}")
    end
  end


  def log(msg)
    logger = nil
    if defined?(Rails.logger)
      Rails.logger.error msg
    else
      $stdout.puts msg
    end
  end

end
