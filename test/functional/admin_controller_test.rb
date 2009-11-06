require 'test_helper'

class AdminControllerTest < ActionController::TestCase

  context "a logged in admin" do

    setup do
      login
    end

    should "be able to get admin page" do
      get :show
      assert_response :success
    end

  end
  
  context "joe schmoe" do
    
    should "not be able to get admin page" do
      get :show
      assert_response 401
      assert @response.body =~ /HTTP Basic: Access denied/
    end
    
  end

end
