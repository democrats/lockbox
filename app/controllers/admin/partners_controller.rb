class Admin::PartnersController < AdminController
  
  def create
    @partner = Partner.new(params[:partner])
    if @partner.save
      redirect_to admin_partner_path(@partner)
    else
      render :action => 'new'
    end
  end

  def new
    @partner = Partner.new
  end
  
  def edit
    @partner = Partner.find params[:id]    
  end
  
  def update
    @partner = Partner.find params[:id]
    if @partner.update_attributes(params[:partner])
      redirect_to admin_partner_path(@partner)
    end
  end

  def show
    @partner = Partner.find params[:id]
  end

  def index
    @partners = Partner.paginate(:page => params[:page])
  end
  
  def destroy
    @partner = Partner.find(params[:id])
    @partner.destroy
    redirect_to admin_partners_path
  end
  
end
