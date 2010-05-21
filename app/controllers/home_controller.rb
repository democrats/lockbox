class HomeController < ApplicationController
  skip_before_filter :require_user
  
  def show
#    if current_user
#      redirect_to partners_path(current_user.api_key)
#    else
#      redirect_to :login
#    end
  end
end
