require 'spec_helper'
require 'rack/test'
require 'lockbox_middleware'

describe LockBox do
  include Rack::Test::Methods

  def app
    # Initialize our LockBox middleware with an "app" that just always returns 200, if it gets .called
    LockBox.new(Proc.new {|env| [200,{},"successfully hit rails app"]})
  end
  
  context "hitting API actions" do
    before do
      @max_age = 3600
      successful_response = mock("MockResponse")
      successful_response.stubs(:code).returns(200)
      successful_response.stubs(:headers).returns({'Cache-Control' => "public,max-age=#{@max_age},must-revalidate"})
      LockBox.stubs(:get).with("/authentication/123456", any_parameters).returns(successful_response)
      bad_response = mock("MockResponse")
      bad_response.stubs(:code).returns(401)
      bad_response.stubs(:headers).returns({'Cache-Control' => 'public,no-cache'})
      LockBox.stubs(:get).with("/authentication/blah", any_parameters).returns(bad_response)
    end

    it "should return 401 for a request that starts with /api with invalid api key" do
      get "/api/some_controller/some_action?key=blah"
      assert_equal 401, last_response.status
    end
      
    it "should return 200 for a request that starts with /api and has api key" do
      get "/api/some_controller/some_action?key=123456"
      assert_equal 200, last_response.status
    end
    
    it "should cache lockbox responses for max-age when Cache-Control allows it" do
      get "/api/some_controller/some_action?key=123456"
      assert_equal 200, last_response.status
      bad_response = mock("MockResponse")
      bad_response.stubs(:headers).returns({'Cache-Control' => 'public,no-cache'})
      bad_response.stubs(:code).returns(401)
      LockBox.stubs(:get).with("/authentication/123456", any_parameters).returns(bad_response)
      get "/api/some_controller/some_action?key=123456"
      assert_equal 200, last_response.status
    end
    
    it "should expire cached lockbox responses when max-age seconds have passed" do
      get "/api/some_controller/some_action?key=123456"
      assert_equal 200, last_response.status
      bad_response = mock("MockResponse")
      bad_response.stubs(:headers).returns({'Cache-Control' => 'public,no-cache'})
      bad_response.stubs(:code).returns(401)
      LockBox.stubs(:get).with("/authentication/123456", any_parameters).returns(bad_response)
      expired_time = @max_age.seconds.since(Time.now)
      Time.stubs(:now).returns(expired_time)
      get "/api/some_controller/some_action?key=123456"
      assert_equal 401, last_response.status
    end
    
    it "should not cache lockbox responses when Cache-Control does not allow it" do
      successful_response = mock("MockResponse")
      successful_response.stubs(:code).returns(200)
      successful_response.stubs(:headers).returns({'Cache-Control' => 'public,no-cache'})
      LockBox.stubs(:get).with("/authentication/123456", any_parameters).returns(successful_response)
      get "/api/some_controller/some_action?key=123456"
      assert_equal 200, last_response.status
      bad_response = mock("MockResponse")
      bad_response.stubs(:code).returns(401)
      bad_response.stubs(:headers).returns({'Cache-Control' => 'public,no-cache'})
      LockBox.stubs(:get).with("/authentication/123456", any_parameters).returns(bad_response)
      get "/api/some_controller/some_action?key=123456"
      assert_equal 401, last_response.status
    end
    
    it "should pass along the rate limit headers to the client if they exist" do
      successful_response = mock("MockResponse")
      successful_response.stubs(:code).returns(200)
      headers = {
        'X-RateLimit-Limit' => '100',
        'X-RateLimit-Remaining' => '99',
        'X-RateLimit-Reset' => 1.hour.from_now.to_i.to_s
      }
      successful_response.stubs(:headers).returns(headers.merge({'Cache-Control' => 'public,no-cache'}))
      LockBox.stubs(:get).with("/authentication/123456", any_parameters).returns(successful_response)
      get "/api/some_controller/some_action?key=123456"
      headers.each_pair do |header,value|
        # just tests that the headers are present; the stubs above ensure the values are what we expect
        assert_equal value, last_response.headers[header]
      end
    end

  end
  
  context "hitting API actions with HMAC auth" do
    before do
      successful_response = mock("MockResponse")
      successful_response.stubs(:code).returns(200)
      successful_response.stubs(:headers).returns({'Cache-Control' => 'public, no-cache'})
      Time.stubs(:now).returns(Time.parse("2010-05-10 16:30:00 EDT"))
      expected_headers = {'X-Referer-Method' => 'GET', 'X-Referer-Date' => [Time.now.httpdate], 'X-Referer-Authorization' => ['AuthHMAC key-id:uxx+EgyzWBKBgS+Y8MzpcWcfy7k='], 'Referer' => 'http://example.org/api/some_controller/some_action'}
      LockBox.stubs(:get).with("/authentication/hmac", {:headers => expected_headers}).returns(successful_response)
      @path = "/api/some_controller/some_action"
      hmac_request = Net::HTTP::Get.new(@path, {'Date' => Time.now.httpdate})
      store = mock("MockStore")
      store.stubs(:[]).with('key-id').returns("123456")
      authhmac = AuthHMAC.new(store)
      authhmac.sign!(hmac_request, 'key-id')
      @hmac_headers = hmac_request.to_hash
    end
    
    it "should return 200 for an HMAC request with a valid auth header" do
      @hmac_headers.each_pair do |key,value|
        header key, value
      end
      get @path
      assert_equal 200, last_response.status
    end
  end

  context "hitting actions without API" do

    it "should not try to authenticate a request that doesn't start with /api" do
      get "/"
      assert_equal 200, last_response.status
      assert_equal("successfully hit rails app", last_response.body)
    end

  end

end