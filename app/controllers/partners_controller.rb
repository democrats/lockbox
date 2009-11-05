class PartnersController < ApplicationController
  def create
    @partner = Partner.new(params[:partner])
    if @partner.save
      redirect_to @partner
    else
      render :action => 'new'
    end
  end

  def new
    @partner = Partner.new
  end

  def show
    @partner = Partner.find params[:id]
  end

  def index
    @partners = Partner.all
  end

end
