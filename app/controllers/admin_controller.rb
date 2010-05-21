class AdminController < ApplicationController
  include AdminAuthentication
  layout "admin"
  
  skip_before_filter :require_user
  before_filter :authenticate
  
end
