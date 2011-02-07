class AuthenticationController < ApplicationController
  skip_before_filter :require_user

  def show
    if params[:id] == 'hmac'
      key = HmacRequest.new(request.headers).hmac_auth()
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

end
