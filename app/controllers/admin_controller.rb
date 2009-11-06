class AdminController < ApplicationController
  include Authentication
  layout "admin"
  
  before_filter :authenticate
  
end
