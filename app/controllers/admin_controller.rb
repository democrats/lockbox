class AdminController < ApplicationController
  include Authentication
  
  before_filter :authenticate
  
  def show
    
  end
  
  
  private
  
  def login_required
    
  end
  
end
