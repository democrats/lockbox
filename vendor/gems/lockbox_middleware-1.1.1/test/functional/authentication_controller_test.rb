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
    
    should "return 200 for successful HMAC authentication" do
      @partner.stubs(:api_key).returns('daad465deb7718a5d0db99345be41e3a1ea0de6d')
      Partner.stubs(:find_by_slug).returns(@partner)
      Partner.stubs(:find_by_api_key).returns(@partner)
      Time.stubs(:now).returns(Time.parse("2010-05-10 16:30:00 EDT"))
      {'X-Referer-Method' => 'GET', 'X-Referer-Date' => [Time.now.httpdate], 'X-Referer-Authorization' => ['AuthHMAC cherry tree cutters:GurpT6GfwItXF3Co4Ut1a3I+3iI='], 'Referer' => 'http://example.org/api/some_controller/some_action'}.each_pair do |e,value|
        @request.env[e] = value
      end
      get :show, :id => 'hmac'
      assert_response 200
    end
    
    should "return 401 for unsuccessful authentication" do
      get :show, :id => 'potato'
      assert_response 401
    end
    
    should "return 401 for unsuccessful HMAC authentication" do
      # pending
    end
    
    should "increment current_request_count for this partner after successful auth" do
      count = @partner.current_request_count
      get :show, :id => @partner.api_key
      assert_equal(count + 1, @partner.current_request_count)
    end
    
    should "return 420 once max_requests has been reached" do
      # 420 is the code the Twitter rate limiting API uses
      @partner.requests_remaining.times do
        @partner.increment_request_count
      end
      get :show, :id => @partner.api_key
      assert_response 420
    end
    
    should "include an error message in the body when rate limited" do
      @partner.requests_remaining.times do
        @partner.increment_request_count
      end
      get :show, :id => @partner.api_key
      assert_match /Too many requests/, @response.body
    end
    
    should "return Cache-Control header after successful auth" do
      get :show, :id => @partner.api_key
      expected_cc_header = ['public', 'no-cache']
      assert_equal expected_cc_header.sort, @response.headers['Cache-Control'].split(/,\s*/).sort
    end
    
    should "return Twitter-style rate limit headers after successful auth" do
      # these headers are documented here: http://apiwiki.twitter.com/Rate-limiting
      get :show, :id => @partner.api_key
      expected_rl_headers = {
        'X-RateLimit-Limit' => @partner.max_requests,
        'X-RateLimit-Remaining' => @partner.requests_remaining,
        'X-RateLimit-Reset' => @partner.max_requests_reset_time,
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
    
    should "return Cache-Control header after successful auth" do
      get :show, :id => @partner.api_key
      expected_cc_header = ['public', "max-age=#{@partner.max_response_cache_time}", 'must-revalidate']
      assert_equal expected_cc_header.sort, @response.headers['Cache-Control'].split(/,\s*/).sort
    end
    
  end
end
