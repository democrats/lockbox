class <%= class_name %>Mailer < ActionMailer::Base
  
  def confirmation(<%= singular_name %>)
    set_host
    recipients <%= singular_name %>.email
    from "confirmation@dnc.org"
    subject "<%= class_name %> Account Confirmation"
    body :<%= singular_name %> => <%= singular_name %>
  end
  
  def fetch_password(<%= singular_name %>)
    set_host
    recipients <%= singular_name %>.email
    from "fetch_password@dnc.org"
    subject "Fetch Password"
    body :<%= singular_name %> => <%= singular_name %>
  end
  
  private
  
  def set_host
    default_url_options[:host] = App[:host]
  end

end
