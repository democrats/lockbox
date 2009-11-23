class FetchPasswordController < ApplicationController
  
  skip_before_filter :require_user, :except => :update
  
  def index
    @<%= singular_name %> = <%= class_name %>.new
  end
  
  def show
    @<%= singular_name %>        = <%= class_name %>.find_by_perishable_token!(params[:id])
    <%= singular_name %>_session = <%= class_name %>Session.new(@<%= singular_name %>)
    
    unless <%= singular_name %>_session.save
      flash[:error] = "Could not authenticate"
      redirect_to fetch_password_index_path
    end
  end
  
  def create
    @<%= singular_name %> = <%= class_name %>.find_by_email(params[:<%= singular_name %>][:email])
    
    if @<%= singular_name %>
      <%= class_name %>Mailer.deliver_fetch_password(@<%= singular_name %>)
      flash[:notice] = "Fetch password email sent to #{@<%= singular_name %>.email}"
      redirect_to root_path
    else
      @<%= singular_name %>      = <%= class_name %>.new
      flash.now[:error] = "Email doesn't exist"
      render :action => :index
    end
  end
  
  def update
    current_user.attributes = params[:<%= singular_name %>]
    
    if current_user.save
      flash[:success] = "Password updated"
      redirect_to root_path
    else
      render :action => :show
    end
  end
  
end