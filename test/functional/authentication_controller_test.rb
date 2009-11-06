require 'test_helper'

class AuthenticationControllerTest < ActionController::TestCase

  context "with an existing partner" do
    setup do
      @partner = Factory(:partner)
    end
    
    should "return 200 for successful authentication" do
      get :show, :id => @partner.api_key
      assert_response 200
    end
    
    should "return 401 for unsuccessful authentication" do
      get :show, :id => 'potato'
      assert_response 401
    end
    
    should "increment current_request_count for this partner after successful auth" do
      count = @partner.current_request_count
      get :show, :id => @partner.api_key
      assert_equal(count + 1, @partner.current_request_count)
    end
    
    should "return 401 once max_requests has been reached" do
      @partner.requests_remaining.times do
        @partner.increment_request_count
      end
      get :show, :id => @partner.api_key
      assert_response 401
    end
    
    

  end

  context "with a partner that has no max requests" do
    setup do
      @partner = Factory(:partner, :max_requests => nil)
    end

    should "allow access" do
      get :show, :id => @partner.api_key
      assert_response 200
    end
  end
end
