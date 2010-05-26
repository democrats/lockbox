class AuthenticationController < ApplicationController
  skip_before_filter :require_user

  class HmacRequest
    attr_accessor :env
    def initialize
      @env = {}
    end
    undef :method
  end

  def show
    if params[:id] == 'hmac'
      hmac_request = HmacRequest.new
      hmac_request.env = request.headers
      {'Content-Type' => 'Content-Type', 'Content-MD5' => 'Content-MD5', 'Date' => 'HTTP_DATE', 'Method' => 'REQUEST_METHOD', 'Authorization' => 'HTTP_AUTHORIZATION'}.each_pair do |h,e|
        hmac_request.env[e] = hmac_request.env["X-Referer-#{h}"] unless hmac_request.env["X-Referer-#{h}"].blank?
      end
      key = hmac_auth(hmac_request)
    else
      key = params[:id]
    end

    @partner = Partner.authenticate(key)

    if @partner.authorized
      if @partner.max_requests.nil?
        expires_in @partner.max_response_cache_time, :public => true, 'must-revalidate' => true
      else
        response.headers["Cache-Control"] = "public, no-cache"
      end
      # can't use head() here because it stupidly alters the camelCase of these header names
      headers.merge!({'X-RateLimit-Limit' => @partner.max_requests.to_s,
        'X-RateLimit-Remaining' => @partner.requests_remaining.to_s,
        'X-RateLimit-Reset' => @partner.max_requests_reset_time.to_s}) unless @partner.max_requests.nil?
      headers.merge!({'X-LockBox-API-Key' => key})
      render :nothing => true, :status => :ok
    elsif @partner.requests_remaining <= 0
      render :four_two_oh, :status => 420
    else
      head 401
    end
  end

  def hmac_auth(request)
    credential_store = Partner.credential_store
    authhmac = AuthHMAC.new(credential_store, {:authenticate_referrer => true})
    if authhmac.authenticated?(request)
      request.env['HTTP_AUTHORIZATION'] =~ /^AuthHMAC ([^:]+):/
      access_key_id = $1
      credential_store[access_key_id]
    else
      false
    end
  end

end
