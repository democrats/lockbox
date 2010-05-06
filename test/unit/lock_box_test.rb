require 'test_helper'
require "rack/test"
require 'ruby-debug'
require 'auth-hmac'

class LockBoxTest < Test::Unit::TestCase
  include Rack::Test::Methods


  def app
    #initialize our LockBox middleware with an "app" that just always returns 200, if it gets .called
    LockBox.new(Proc.new {|env| [200,{},"successfully hit rails app"]})
  end

  context "hitting API actions" do
    setup do
      successful_response = mock("MockResponse")
      successful_response.stubs(:code).returns(200)
      LockBox.stubs(:get).with("/authentication/123456", any_parameters).returns(successful_response)
      bad_response = mock("MockResponse")
      bad_response.stubs(:code).returns(401)
      LockBox.stubs(:get).with("/authentication/blah", any_parameters).returns(bad_response)
    end

    should "return 401 for a request that starts with /api with invalid api key" do
      get "/api/some_controller/some_action?key=blah"
      assert_equal 401, last_response.status
    end
    
    should "return 200 for a request that starts with /api and has api key" do
      get "/api/some_controller/some_action?key=123456"
      assert_equal 200, last_response.status
    end

  end

  context "hitting API actions with HMAC auth" do
    setup do
      successful_response = mock("MockResponse")
      successful_response.stubs(:code).returns(200)
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
    
    should "return 200 for an HMAC request with a valid auth header" do
      @hmac_headers.each_pair do |key,value|
        header key, value
      end
      get @path
      assert_equal 200, last_response.status
    end
  end

  context "hitting actions without API" do

    should "not try to authenticate a request that doesn't start with /api" do
      get "/"
      assert_equal 200, last_response.status
      assert_equal("successfully hit rails app", last_response.body)
    end

  end

end