require 'test_helper'
require "rack/test"
require 'ruby-debug'

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
      LockBox.stubs(:get).with("/authentication/123456").returns(successful_response)
      bad_response = mock("MockResponse")
      bad_response.stubs(:code).returns(401)
      LockBox.stubs(:get).with("/authentication/blah").returns(bad_response)
    end

    should "return 401 for a request that starts with /api with no api key" do
      get "/api/blah/some_controller/some_action"
      assert_equal 401, last_response.status
    end
    
    should "return 200 for a request that starts with /api and has api key" do
      get "/api/123456/some_controller/some_action"
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