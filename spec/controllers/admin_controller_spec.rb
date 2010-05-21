require 'spec_helper'

describe AdminController do
  include HelperMethods

  context "a logged in admin" do
    before do
      admin_login
    end

    it "should be able to get admin page" do
      get :show
      response.should be_success
    end

  end
  
  context "joe schmoe" do
    
    it "should not be able to get admin page" do
      get :show
      response.should_not be_success
      response.status.should =~ /401/
      response.body.should =~ /HTTP Basic: Access denied/
    end
    
  end

end