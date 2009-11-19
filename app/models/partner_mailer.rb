class PartnerMailer < ActionMailer::Base
  
  def confirmation(partner)
    recipients partner.email
    from "test@dnc.org"
    subject "Partner Account Confirmation"
    body :partner => partner
  end

end
