require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase

  context "Test Exception Notifier" do

    should "raise exception when passed proper params" do
      assert_raise(RuntimeError) { get :test_exception_notification, :id => 'blowup' }
    end

    context "without proper params" do
      
      setup do
        get :test_exception_notification
      end
      
      should_respond_with :success
      
      should "say access denied" do
        assert_equal("Access Denied", @response.body)
      end
      
    end

    
  end

end
