class <%= class_name %>SessionsController < ApplicationController

  skip_before_filter :require_user, :only => [:create, :new]
  before_filter :require_no_user, :only => [:create, :new]
  
  def new
    @<%= singular_name %>_session = <%= class_name %>Session.new
  end
  
  def create
    @<%= singular_name %>_session = <%= class_name %>Session.new(params[:<%= singular_name %>_session])

    if @<%= singular_name %>_session.save
      flash[:success] = "You have been signed in"
      redirect_back_or_default root_path
    else
      @<%= singular_name %>_session.errors.clear
      flash.now[:error]  = "Email doesn't exist or bad Pasword"
      flash.now[:notice] = "<a href='#{fetch_password_index_path}'>Did you forget your password?</a>"
      render :action => :new
    end
  end
  
  def destroy
    current_user_session.destroy
    flash[:success] = "You have been logged out"
    redirect_back_or_default root_path
  end

end