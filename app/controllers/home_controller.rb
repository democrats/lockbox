class HomeController < ApplicationController
  skip_before_filter :require_user
  
  def show
    
  end

end
