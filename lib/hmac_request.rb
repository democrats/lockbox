class HmacRequest
  attr_accessor :request, :env, :body, :hmac_id, :hmac_hash
  undef :method
  
  @@valid_date_window = 600 # seconds
  
  HEADER_TO_ENV_MAP = { 'Content-Type'  => 'CONTENT_TYPE', 
                        'Content-MD5'   => 'CONTENT_MD5', 
                        'Date'          => 'HTTP_DATE', 
                        'Method'        => 'REQUEST_METHOD', 
                        'Authorization' => 'HTTP_AUTHORIZATION' }

  def initialize(env)
    @request = Rack::Request.new(env)
    @env = @request.env
    @body = @request.body if has_body?(@env['REQUEST_METHOD'])
    HEADER_TO_ENV_MAP.each_pair do |h,e|
      @env[e] = @env["X-Referer-#{h}"] unless @env["X-Referer-#{h}"].blank?
    end
  end

  def path
    #use Referer if it's there, which it will be when this gets called while hitting the AuthenticationController
    if @env['Referer'] =~ /^(?:http:\/\/)?[^\/]*(\/.*)$/
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


  def hmac_auth()
    credential_store = Partner.credential_store
    authhmac = AuthHMAC.new(credential_store)
    if authhmac.authenticated?(self) && (@env['HTTP_DATE'].blank? || self.date_is_recent? )
      credential_store[self.hmac_id]
    else
      log_auth_error
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
      Rails.logger.error "Request date #{req_date} is more than #{@@valid_date_window} seconds old"
      return false
    else
      return true
    end
  end
  
  def log_auth_error
    Rails.logger.error "Logging Lockbox HMAC authorization error:"
    Rails.logger.error "Path: #{self.path}"      
    ['CONTENT-TYPE', 'CONTENT-MD5', 'HTTP_DATE', 'REQUEST_METHOD', 'Authorization'].each do |header|
      Rails.logger.error "#{header}: #{@env[header]}"
    end

    Rails.logger.error "HMAC Canonical String: #{ AuthHMAC::CanonicalString.new(self).inspect}"

    if self.hmac_id.nil?
      Rails.logger.error("HMAC failed because request is not signed")
    else
      Rails.logger.error("HMAC failed - expected #{AuthHMAC.signature(self,self.hmac_id)} but was #{$2}")
    end
  end


end