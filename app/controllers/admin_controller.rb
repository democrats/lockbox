class AdminController < ApplicationController
  include Authentication
  layout "admin"
  
  before_filter :authenticate
  
  def show
    
  end
  
  
  private
  
  def login_required
    
  end
  
end
