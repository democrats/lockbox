class PartnersController < ApplicationController
  skip_before_filter :require_user, :only => [:new, :create]
  before_filter :load_partner, :only => [:show, :edit, :update]

  def index
    redirect_to partner_path(current_user.api_key)
  end
  
  def show
    respond_to do |format|
      format.html {}
      format.json { render :json => @partner.to_json(:only => [:name, :api_key, :organization, :phone_number, :email]) }
    end

  end

  def new
    @partner = Partner.new
  end

  def create
    @partner = Partner.new(params[:partner])
    
    if @partner.save
      PartnerMailer.deliver_confirmation(@partner)
      flash[:notice] = "A confirmation email has been sent to you"
      redirect_to partner_path(@partner.api_key)
    else
      render :action => 'new'
    end
  end
  
  def edit
  end
  
  def update
    @partner.attributes = params[:partner]
    
    if @partner.save
      redirect_to partner_path(@partner.api_key)
    else
      render :action => :edit
    end
  end

  def load_partner
    partner = Partner.find_by_api_key(params[:id])
    if partner == current_user
      @partner = partner
    else
      
      render :file => "#{Rails.public_path}/401.html", :status => :unauthorized
      return
    end
  end
  
end
