class ConfirmationController < ApplicationController

  skip_before_filter :require_user

  def update
    @<%= singular_name %>           = <%= class_name %>.find_by_perishable_token!(params[:perishable_token])
    @<%= singular_name %>.confirmed = true
    @<%= singular_name %>.save
    <%= class_name %>Session.create(@<%= singular_name %>)
    flash[:success]    = "You account has been confirmed."
    redirect_to root_path
  end

end
