class Admin::ProtectedApplicationsController < AdminController

  def index
    @protected_applications = ProtectedApplication.all
  end

  def show
    @protected_application = ProtectedApplication.find(params[:id])        
  end

  def new
    @protected_application = ProtectedApplication.new
  end

  def edit
    @protected_application = ProtectedApplication.find(params[:id])    
  end

  def destroy
    @protected_application = ProtectedApplication.find(params[:id])
    if @protected_application.destroy
      flash[:notice] = "Success!"
    else
      flash[:error] = "Failed!"
    end
    redirect_to admin_protected_applications_path
  end

  def update
    @protected_application = ProtectedApplication.find(params[:id])
    if @protected_application.update_attributes params[:protected_application]
      redirect_to admin_protected_applications_path
    else
      render :action => 'edit'
    end
  end

  def create
    @protected_application = ProtectedApplication.new(params[:protected_application])
    if @protected_application.save
      redirect_to admin_protected_applications_path
    else
      render :action => 'new'
    end
  end
end