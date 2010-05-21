class FetchPasswordController < ApplicationController
  
  skip_before_filter :require_user, :except => :update
  
  def index
    @partner = Partner.new
  end
  
  def show
    @partner        = Partner.find_by_perishable_token!(params[:id])
    partner_session = PartnerSession.new(@partner)
    
    unless partner_session.save
      flash[:error] = "Could not authenticate"
      redirect_to fetch_password_index_path
    end
  end
  
  def create
    @partner = Partner.find_by_email(params[:partner][:email])
    
    if @partner
      PartnerMailer.deliver_fetch_password(@partner)
      flash[:notice] = "Fetch password email sent to #{@partner.email}"
      redirect_to root_path
    else
      @partner      = Partner.new
      flash[:error] = "Email doesn't exist"
      render :action => :index
    end
  end
  
  def update
    current_user.attributes = params[:partner]
    
    if current_user.save
      flash[:success] = "Password updated"
      redirect_to root_path
    else
      render :action => :show
    end
  end
  
end