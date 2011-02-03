require 'spec_helper'
require 'rack/test'
require 'lockbox_middleware'
require 'digest/md5'
require 'cgi'

describe 'LockBox' do
  include Rack::Test::Methods

  def app
    # Initialize our LockBox middleware with an "app" that just always returns 200, if it gets .called
    LockBox.new(Proc.new {|env| [200,{'Content-Type' => 'text/plain'},["successfully hit rails app"]]})
  end
  
  def safely_edit_config_file(settings)
    Object.class_eval do
      remove_const LockBox.to_s if const_defined? :LockBox
    end

    env = Rails.env if defined?(Rails)
    env ||= ENV['RACK_ENV']
    env ||= 'test'
    @config_file = File.join(File.dirname(__FILE__),'..','..','config','lockbox.yml')
    @tmp_config_file = "#{@config_file}.testing"
    FileUtils.cp(@config_file, @tmp_config_file)
    config = YAML.load_file(@config_file)
    settings.each_pair do |setting,value|
      config[env][setting.to_s] = value
    end
    File.open( @config_file, 'w' ) do |out|
      YAML.dump( config, out )
    end
    load 'lib/lockbox_middleware.rb'
  end
  
  context "setting the base_uri" do
    let(:base_uri) { "http://localhost:3001" }
    
    it "should use the base_uri specified in the config" do
      safely_edit_config_file({:base_uri => base_uri})
      LockBox.base_uri.should == base_uri
    end
    
    after :each do
      if @tmp_config_file && @config_file
        FileUtils.mv(@tmp_config_file, @config_file)
      end
    end
  end
  
  context "setting the protected paths" do
    let(:path1) { "^/api/" }
    let(:path2) { "^/foo/bar/" }
    let(:path3) { "/lookup/?$" }
    
    before :each do
      safely_edit_config_file({:protect_paths => [path1, path2, path3]})
      successful_response = mock("MockResponse")
      successful_response.stubs(:code).returns(200)
      successful_response.stubs(:headers).returns({'Cache-Control' => 'public,no-cache'})
      LockBox.stubs(:get).with("/authentication/123456", any_parameters).returns(successful_response)
      bad_response = mock("MockResponse")
      bad_response.stubs(:code).returns(401)
      bad_response.stubs(:headers).returns({'Cache-Control' => 'public,no-cache'})
      LockBox.stubs(:get).with("/authentication/invalid", any_parameters).returns(bad_response)
    end
    
    it "should protect path1" do
      get "/api/foo?key=invalid"
      last_response.status.should == 401
      get "/api/foo?key=123456"
      last_response.status.should == 200
    end
    
    it "should protect path2" do
      get "/foo/bar/baz?key=invalid"
      last_response.status.should == 401
      get "/foo/bar/baz?key=123456"
      last_response.status.should == 200
    end
    
    it "should protect path3" do
      get "/polling_place/lookup?key=invalid"
      last_response.status.should == 401
      get "/polling_place/lookup?key=123456"
      last_response.status.should == 200
    end
    
    it "should not protect other paths" do
      get "/bar/baz"
      last_response.status.should == 200
      last_response.body.should == "successfully hit rails app"
    end
    
    after :each do
      if @tmp_config_file && @config_file
        FileUtils.mv(@tmp_config_file, @config_file)
      end
    end
  end
  
  context "hitting API actions with key-based authentication" do
    before :each do
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
  
    context "with invalid api key" do
      it "should return 401 for a protected path request" do
        get "/api/some_controller/some_action?key=blah"
        last_response.status.should == 401
      end
    
      it "should return an array as the response body" do
        # Rack compliance thing
        env = Rack::MockRequest.env_for "/api/some_controller/some_action?key=blah"
        app.call(env)[2].should be_an_instance_of(Array)
      end
    end
      
    context "with valid api key" do
      it "should return 200 for a request that starts with /api and has api key" do
        get "/api/some_controller/some_action?key=123456"
        last_response.status.should == 200
      end
    
      it "should have a Content-Type header" do
        # Rack compliance bug
        env = Rack::MockRequest.env_for "/api/some_controller/some_action?key=123456"
        app.call(env)[1].should include('Content-Type')
      end
    end
    
    it "should cache lockbox responses for max-age when Cache-Control allows it" do
      get "/api/some_controller/some_action?key=123456"
      last_response.status.should == 200
      bad_response = mock("MockResponse")
      bad_response.stubs(:headers).returns({'Cache-Control' => 'public,no-cache'})
      bad_response.stubs(:code).returns(401)
      LockBox.stubs(:get).with("/authentication/123456", any_parameters).returns(bad_response)
      get "/api/some_controller/some_action?key=123456"
      last_response.status.should == 200
    end
    
    it "should expire cached lockbox responses when max-age seconds have passed" do
      get "/api/some_controller/some_action?key=123456"
      last_response.status.should == 200
      bad_response = mock("MockResponse")
      bad_response.stubs(:headers).returns({'Cache-Control' => 'public,no-cache'})
      bad_response.stubs(:code).returns(401)
      LockBox.stubs(:get).with("/authentication/123456", any_parameters).returns(bad_response)
      expired_time = Time.at(Time.now.to_i + @max_age)
      Time.stubs(:now).returns(expired_time)
      get "/api/some_controller/some_action?key=123456"
      last_response.status.should == 401
    end
    
    it "should not cache lockbox responses when Cache-Control does not allow it" do
      successful_response = mock("MockResponse")
      successful_response.stubs(:code).returns(200)
      successful_response.stubs(:headers).returns({'Cache-Control' => 'public,no-cache'})
      LockBox.stubs(:get).with("/authentication/123456", any_parameters).returns(successful_response)
      get "/api/some_controller/some_action?key=123456"
      last_response.status.should == 200
      bad_response = mock("MockResponse")
      bad_response.stubs(:code).returns(401)
      bad_response.stubs(:headers).returns({'Cache-Control' => 'public,no-cache'})
      LockBox.stubs(:get).with("/authentication/123456", any_parameters).returns(bad_response)
      get "/api/some_controller/some_action?key=123456"
      last_response.status.should == 401
    end
    
    it "should pass along the rate limit headers to the client if they exist" do
      successful_response = mock("MockResponse")
      successful_response.stubs(:code).returns(200)
      headers = {
        'X-RateLimit-Limit' => '100',
        'X-RateLimit-Remaining' => '99',
        'X-RateLimit-Reset' => (Time.now.to_i + 3600).to_s
      }
      successful_response.stubs(:headers).returns(headers.merge({'Cache-Control' => 'public,no-cache'}))
      LockBox.stubs(:get).with("/authentication/123456", any_parameters).returns(successful_response)
      get "/api/some_controller/some_action?key=123456"
      headers.each_pair do |header,value|
        # just tests that the headers are present; the stubs above ensure the values are what we expect
        last_response.headers[header].should == value
      end
    end
  
  end
  
  context "hitting API actions via GET requests with HMAC auth" do
    before :each do
      successful_response = mock("MockResponse")
      successful_response.stubs(:code).returns(200)
      successful_response.stubs(:headers).returns({'Cache-Control' => 'public, no-cache'})
      Time.stubs(:now).returns(Time.parse("2010-05-10 16:30:00 EDT"))
      valid_headers = {'X-Referer-Method' => 'GET', 'X-Referer-Date' => [Time.now.httpdate], 'X-Referer-Authorization' => ['AuthHMAC key-id:uxx+EgyzWBKBgS+Y8MzpcWcfy7k='], 'Referer' => 'http://example.org/api/some_controller/some_action'}
      LockBox.stubs(:get).with("/authentication/hmac", {:headers => valid_headers, :request => {:application_name => 'test'}}).returns(successful_response)
      
      bad_response = mock("MockResponse")
      bad_response.stubs(:code).returns(401)
      bad_response.stubs(:headers).returns({'Cache-Control' => 'public, no-cache'})
      invalid_headers = {'X-Referer-Method' => 'GET', 'X-Referer-Date' => [Time.now.httpdate], 'X-Referer-Authorization' => 'foo', 'Referer' => 'http://example.org/api/some_controller/some_action'}
      LockBox.stubs(:get).with("/authentication/hmac", {:headers => invalid_headers, :request => {:application_name => 'test'}}).returns(bad_response)
      
      @path = "/api/some_controller/some_action"
      
      hmac_request = Net::HTTP::Get.new(@path, {'Date' => Time.now.httpdate})
      authhmac = AuthHMAC.new({"key-id" => "123456"})
      authhmac.sign!(hmac_request, 'key-id')
      @hmac_headers = hmac_request.to_hash
    end
    
    it "should return 200 for an HMAC request with a valid auth header" do
      @hmac_headers.each_pair do |key,value|
        header key, value
      end
      get @path
      last_response.status.should == 200
    end
  
    it "should return 200 for a valid HMAC request from a .NET client" do
      # first test w/ a Date header too, then test w/o a separate Date header
      @hmac_headers['X-AuthHMAC-Request-Date'] = @hmac_headers['Date']
      @hmac_headers.each_pair do |key,value|
        header key, value
      end
      get @path
      last_response.status.should == 200
    end
  
    it "should return 200 for a valid HMAC request from a .NET client with no Date header" do
      @hmac_headers['X-AuthHMAC-Request-Date'] = @hmac_headers.delete('Date')
      @hmac_headers.each_pair do |key,value|
        header key, value
      end
      get @path
      last_response.status.should == 200
    end
    
    it "should return 401 for an HMAC request with an invalid auth header" do
      @hmac_headers['authorization'] = 'foo'
      @hmac_headers.each_pair do |key,value|
        header key, value
      end
      get @path
      last_response.status.should == 401
    end
  
  end
  
  context "hitting API actions via POST requests with HMAC auth" do
    before :each do
      @content = "" # TODO: Rack::Test sucks at some stuff, like setting the request body when making a POST
      @content_md5 = Digest::MD5.hexdigest(CGI::escape(@content))
      
      successful_response = mock("MockResponse")
      successful_response.stubs(:code).returns(200)
      successful_response.stubs(:headers).returns({'Cache-Control' => 'public, no-cache'})
      Time.stubs(:now).returns(Time.parse("2010-05-10 16:30:00 EDT"))
      valid_headers = {'X-Referer-Method' => 'POST', 'X-Referer-Content-Type' => 'application/x-www-form-urlencoded', 'X-Referer-Date' => [Time.now.httpdate], 'X-Referer-Authorization' => ['AuthHMAC key-id:+qPzK7cJdJbhsiCRcXa8A8LLrF8='], 'Referer' => 'http://example.org/api/some_controller/some_action', 'X-Referer-Content-MD5' => @content_md5}
      LockBox.stubs(:get).with("/authentication/hmac", {:headers => valid_headers, :request => {:application_name => 'test'}}).returns(successful_response)
      
      bad_response = mock("MockResponse")
      bad_response.stubs(:code).returns(401)
      bad_response.stubs(:headers).returns({'Cache-Control' => 'public, no-cache'})
      invalid_headers = {'X-Referer-Method' => 'POST', 'X-Referer-Content-Type' => 'application/x-www-form-urlencoded', 'X-Referer-Date' => [Time.now.httpdate], 'X-Referer-Authorization' => ['AuthHMAC key-id:u2Jlv0f6ZG59HQNGk+Bgq3/vHvM='], 'Referer' => 'http://example.org/api/some_controller/some_action', 'X-Referer-Content-MD5' => @content_md5}
      LockBox.stubs(:get).with("/authentication/hmac", {:headers => invalid_headers, :request => {:application_name => 'test'}}).returns(bad_response)
      
      @path = "/api/some_controller/some_action"
      
      hmac_request = Net::HTTP::Post.new(@path, {'Date' => Time.now.httpdate})
      hmac_request.body = @content
      authhmac = AuthHMAC.new({"key-id" => "123456"})
      authhmac.sign!(hmac_request, 'key-id')
      @hmac_headers = hmac_request.to_hash
    end
    
    it "should return 200 for an HMAC request with a valid auth header" do
      @hmac_headers.each_pair do |key,value|
        header key, value
      end
      post @path, @content
      last_response.status.should == 200
    end
    
    it "should return 401 for an HMAC request with an invalid auth header" do
      @hmac_headers['authorization'] = ['AuthHMAC key-id:u2Jlv0f6ZG59HQNGk+Bgq3/vHvM=']
      @hmac_headers.each_pair do |key,value|
        header key, value
      end
      post @path, @content
      last_response.status.should == 401
    end
    
  end
  
  context "hitting actions without API" do
  
    it "should not try to authenticate a request that doesn't start with /api" do
      get "/"
      last_response.status.should == 200
      last_response.body.should == "successfully hit rails app"
    end
  
  end
  
  context "hitting API actions with HMAC auth caching" do
    before :each do
      Time.stubs(:now).returns(Time.parse("2010-05-10 16:30:00 EDT"))
      @response_with_caching = mock("MockResponse")
      @response_with_caching.stubs(:code).returns(200)
      @response_with_caching.stubs(:headers).returns({'Cache-Control' => "public,max-age=3600,must-revalidate", "X-LockBox-API-Key" => "123456"})

      @response_without_caching = mock("MockResponse")
      @response_without_caching.stubs(:code).returns(200)
      @response_without_caching.stubs(:headers).returns({'Cache-Control' => 'public, no-cache', "X-LockBox-API-Key" => "123456"})

      @bad_response = mock("MockResponse")
      @bad_response.stubs(:code).returns(401)
      @bad_response.stubs(:headers).returns({'Cache-Control' => 'public, no-cache'})

      @path = "/api/some_controller/some_action"

      hmac_request = Net::HTTP::Get.new(@path, {'Date' => Time.now.httpdate, 'Referer' =>'http://example.org/api/some_controller/some_action' })
      authhmac = AuthHMAC.new({'key-id' => '123456'})
      authhmac.sign!(hmac_request, 'key-id')
      @hmac_headers = hmac_request.to_hash
      @hmac_headers.each_pair do |key,value|
        header key, value
      end

    end
    
    after :each do
      app.cache.clear
    end


    it "should cache lockbox responses for max-age when Cache-Control allows it" do
      LockBox.stubs(:get).returns(@response_with_caching)
      get @path
      last_response.status.should == 200
      LockBox.stubs(:get).returns(@bad_response)
      get @path
      last_response.status.should == 200
    end
    
    it "should expire cached lockbox responses when max-age seconds have passed" do
      LockBox.stubs(:get).returns(@response_with_caching)
      get @path
      last_response.status.should == 200
      expired_time = Time.at(Time.now.to_i + 3600)
      Time.stubs(:now).returns(expired_time)
      LockBox.stubs(:get).returns(@bad_response)
      get @path
      last_response.status.should == 401
    end

    it "should not cache lockbox responses when Cache-Control does not allow it" do
      LockBox.stubs(:get).returns(@response_without_caching)
      get @path
      last_response.status.should == 200
      LockBox.stubs(:get).returns(@bad_response)
      get @path
      last_response.status.should == 401
    end    
  end

end
