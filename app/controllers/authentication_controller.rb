class AuthenticationController < ApplicationController
  skip_before_filter :require_user
  @@valid_date_window = 600 # seconds

  class HmacRequest
    attr_accessor :env
    
    def initialize
      @env = {}
    end
    
    def path
      @env['Referer'] =~ /^(?:http:\/\/)?[^\/]*(\/.*)$/
      $1
    end
    
    undef :method
  end

  def show
    if params[:id] == 'hmac'
      
      hmac_request = HmacRequest.new
      hmac_request.env = request.headers
      {'Content-Type' => 'CONTENT-TYPE', 'Content-MD5' => 'CONTENT-MD5', 'Date' => 'HTTP_DATE', 'Method' => 'REQUEST_METHOD', 'Authorization' => 'HTTP_AUTHORIZATION'}.each_pair do |h,e|
        hmac_request.env[e] = hmac_request.env["X-Referer-#{h}"] unless hmac_request.env["X-Referer-#{h}"].blank?
      end
      key = hmac_auth(hmac_request)
    else
      key = params[:id]
    end

    @partner = Partner.authenticate(key)

    if @partner.authorized(params[:application_name])
      if @partner.unlimited?
        expires_in @partner.max_response_cache_time, :public => true, 'must-revalidate' => true
      else
        response.headers["Cache-Control"] = "public, no-cache"
      end
      # can't use head() here because it stupidly alters the camelCase of these header names
      headers.merge!({'X-RateLimit-Limit' => @partner.max_requests.to_s,
        'X-RateLimit-Remaining' => @partner.requests_remaining.to_s,
        'X-RateLimit-Reset' => @partner.max_requests_reset_time.to_s}) unless @partner.unlimited?
      headers.merge!({'X-LockBox-API-Key' => key})
      render :nothing => true, :status => :ok
    elsif !@partner.unlimited? && @partner.requests_remaining <= 0
      render :four_two_oh, :status => 420
    else
      head 401
    end
  end

  def hmac_auth(request)
    credential_store = Partner.credential_store
    authhmac = AuthHMAC.new(credential_store)
    if authhmac.authenticated?(request) && (request.env['HTTP_DATE'].blank? || date_is_recent?(request) )
      request.env['HTTP_AUTHORIZATION'] =~ /^AuthHMAC ([^:]+):/
      access_key_id = $1
      credential_store[access_key_id]
    else
      #request.env.collect{important things}
      #{'Content-Type' => 'CONTENT-TYPE', 'Content-MD5' => 'CONTENT-MD5', 'Date' => 'HTTP_DATE', 'Method' => 'REQUEST_METHOD', 'Authorization' => 'HTTP_AUTHORIZATION'}.each_pair do |h,e|
      logger.error "Logging Lockbox HMAC authorization error:"
      logger.error "Path: #{request.path}"      
      ['CONTENT-TYPE', 'CONTENT-MD5', 'HTTP_DATE', 'REQUEST_METHOD', 'Authorization'].each do |header|
        logger.error "#{header}: #{request.env[header]}"
      end

      logger.error "Canonical String: #{ AuthHMAC::CanonicalString.new(request).inspect}"
      request.env['HTTP_AUTHORIZATION'] =~ /^AuthHMAC ([^:]+):(.*)$/
      access_key_id = $1
      hash = $2
      if access_key_id.nil?
        logger.error("HMAC failed because request is not signed")
      else
        logger.error("HMAC failed - expected #{AuthHMAC.signature(request,access_key_id)} but was #{$2}")
      end

      false
    end
  end

  def date_is_recent?(request)
    req_date = nil

    begin
      req_date = Time.httpdate(request.env['HTTP_DATE'])
    rescue Exception => ex
      if ex.message =~ /not RFC 2616 compliant/
        # try rfc2822
        req_date = Time.rfc2822(request.env['HTTP_DATE'])
      else
        raise ex
      end
    end

    if Time.now.to_i - req_date.to_i >= @@valid_date_window
      logger.error "Request date #{req_date} is more than #{@@valid_date_window} seconds old"
      return false
    else
      return true
    end
  end

end
