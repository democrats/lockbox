class PartnersController < ApplicationController
  skip_before_filter :require_user, :only => [:new, :create]
  
  def show
    @partner = current_user
  end

  def new
    @partner = Partner.new
  end

  def create
    @partner = Partner.new(params[:partner])
    
    if @partner.save
      PartnerMailer.deliver_confirmation(@partner)
      redirect_to partner_path(@partner)
    else
      render :action => 'new'
    end
  end
  
  def edit
    @partner = current_user
  end
  
  def update
    @partner = current_user
    @partner.attributes = params[:partner]
    
    if @partner.save
      redirect_to partner_path(@partner)
    else
      render :action => :edit
    end
  end
  
end
