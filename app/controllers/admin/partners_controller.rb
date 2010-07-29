class Admin::PartnersController < AdminController

  def index
    @partners = Partner.all
  end

  def show
    @partner = Partner.find(params[:id])
    @protected_applications = ProtectedApplication.all       
  end

  def edit
    @partner = Partner.find(params[:id])
    @protected_applications = ProtectedApplication.all           
  end


  def update
    params[:partner][:protected_application_ids] ||= []          #zero out if they are all unchecked. 
    @partner = Partner.find(params[:id])
    if @partner.update_attributes(params[:partner])
      redirect_to admin_partners_path
    else
      render :action => 'edit'
    end
  end

  def destroy
   @partner = Partner.find(params[:id]) 
   if @partner.destroy
      flash[:notice] = "Success!"
    else
      flash[:error] = "Failed!"
    end
    redirect_to admin_partners_path
  end

end
