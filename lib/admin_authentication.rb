module AdminAuthentication
  private

  def authenticate
    authenticate_or_request_with_http_basic do |user_name, password|
      user_name == "admin" && password == "somethingcute"
    end
  end
end