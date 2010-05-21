class PartnerMailer < ActionMailer::Base
  
  def confirmation(partner)
    set_host
    recipients partner.email
    from "test@dnc.org"
    subject "Partner Account Confirmation"
    body :partner => partner
  end
  
  def fetch_password(partner)
    set_host
    recipients partner.email
    from "test@dnc.org"
    subject "Fetch Password"
    body :partner => partner
  end
  
  private
  
  def set_host
    default_url_options[:host] = App[:host]
  end

end
