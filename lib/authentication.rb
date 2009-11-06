module Authentication
  private

  def authenticate
    authenticate_or_request_with_http_basic do |user_name, password|
      user_name == "admin" && password == "10ckb0X"
    end
  end
end