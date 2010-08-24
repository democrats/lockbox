class <%= class_name.pluralize %>Controller < ApplicationController
  skip_before_filter :require_user, :only => [:new, :create]
  
  def show
    @<%= singular_name %> = current_user
  end

  def new
    @<%= singular_name %> = <%= class_name %>.new
  end

  def create
    @<%= singular_name %> = <%= class_name %>.new(params[:<%= singular_name %>])
    
    if @<%= singular_name %>.save
      <%= class_name %>Mailer.deliver_confirmation(@<%= singular_name %>)
      flash[:notice] = "A confirmation email has been sent to you"
      redirect_to root_path
    else
      render :action => 'new'
    end
  end
  
  def edit
    @<%= singular_name %> = current_user
  end
  
  def update
    @<%= singular_name %> = current_user
    @<%= singular_name %>.attributes = params[:<%= singular_name %>]
    
    if @<%= singular_name %>.save
      redirect_to <%= singular_name %>_path(@<%= singular_name %>)
    else
      render :action => :edit
    end
  end
  
end
