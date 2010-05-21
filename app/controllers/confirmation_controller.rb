class ConfirmationController < ApplicationController

  skip_before_filter :require_user

  def update
    @partner           = Partner.find_by_perishable_token!(params[:perishable_token])
    @partner.confirmed = true
    @partner.save
    PartnerSession.create(@partner)
    flash[:success]    = "You account has been confirmed."
    redirect_to root_path
  end

end
