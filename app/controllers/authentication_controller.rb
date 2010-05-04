class AuthenticationController < ApplicationController
  skip_before_filter :require_user

  def show
    if partner = Partner.authenticate(params[:id])
      expires_in partner.max_response_cache_time, :public => true, 'must-revalidate' => true
      # can't use head() here because it stupidly alters the camelCase of these header names
      headers.merge!({'X-RateLimit-Limit' => partner.max_requests.to_s, 'X-RateLimit-Remaining' => partner.requests_remaining.to_s, 'X-RateLimit-Reset' => partner.max_requests_reset_time.to_s}) unless partner.max_requests.nil?
      render :nothing => true, :status => :ok
    else
      head 401
    end
  end

end
