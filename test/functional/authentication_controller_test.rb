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
    
    should "return Cache-Control header after successful auth" do
      get :show, :id => @partner.api_key
      expected_cc_header = ['public', "max-age=#{@partner.max_response_cache_time}", 'must-revalidate']
      assert_equal expected_cc_header.sort, @response.headers['Cache-Control'].split(/,\s*/).sort
    end
    
    should "return Twitter-style rate limit headers after successful auth" do
      # these headers are documented here: http://apiwiki.twitter.com/Rate-limiting
      get :show, :id => @partner.api_key
      expected_rl_headers = {
        'X-RateLimit-Limit' => @partner.max_requests,
        'X-RateLimit-Remaining' => @partner.requests_remaining,
        'X-RateLimit-Reset' => @partner.max_requests_reset,
      }
      rl_headers_received = Hash.new
      expected_rl_headers.keys.map { |header|
        rl_headers_received[header] = @response.headers[header].to_i
      }
      assert_equal expected_rl_headers, rl_headers_received
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
    
    should "not return rate limit headers after successful auth" do
      get :show, :id => @partner.api_key
      @response.headers.each_key do |header|
        assert_no_match(/^X-RateLimit-/,header)
      end
    end
  end
end
