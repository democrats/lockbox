require File.dirname(__FILE__) + '/spec_helper.rb'
require "net/http"
require 'time'
require 'yaml'
require 'rubygems'
gem 'actionpack'
gem 'activeresource'
require 'action_controller'
require 'action_controller/test_process'
require 'active_resource'
require 'active_resource/http_mock'
require 'ruby-debug'

# Class for doing a custom signature
class CustomSignature < String
  def initialize(request)
    self << "Custom signature string: #{request.method}"
  end
end

def signature(value, secret)
  digest = OpenSSL::Digest::Digest.new('sha1')
  Base64.encode64(OpenSSL::HMAC.digest(digest, secret, value)).strip
end

describe AuthHMAC do
  before(:each) do
    @request = Net::HTTP::Put.new("/path/to/put?foo=bar&bar=foo", 
      'content-type' => 'text/plain', 
      'content-md5' => 'blahblah', 
      'date' => "Thu, 10 Jul 2008 03:29:56 GMT")
  end

  describe ".canonical_string" do
    it "should generate a canonical string using default method" do
      # debugger
      AuthHMAC.canonical_string(@request).should == "PUT\ntext/plain\nblahblah\nThu, 10 Jul 2008 03:29:56 GMT\n/path/to/put"
    end
  end
  
  describe ".signature" do
    it "should generate a valid signature string for a secret" do
      AuthHMAC.signature(@request, 'secret').should == "71wAJM4IIu/3o6lcqx/tw7XnAJs="
    end
  end

  describe ".sign!" do
    before(:each) do
      @request = Net::HTTP::Put.new("/path/to/put?foo=bar&bar=foo", 
        'content-type' => 'text/plain', 
        'content-md5' => 'blahblah', 
        'date' => "Thu, 10 Jul 2008 03:29:56 GMT")
    end

    it "should sign using the key passed in as a parameter" do
     AuthHMAC.sign!(@request, "my-key-id", "secret")
     @request['Authorization'].should == "AuthHMAC my-key-id:71wAJM4IIu/3o6lcqx/tw7XnAJs="
    end

    it "should sign using custom service id" do
      AuthHMAC.sign!(@request, "my-key-id", "secret", { :service_id => 'MyService' })
      @request['Authorization'].should == "MyService my-key-id:71wAJM4IIu/3o6lcqx/tw7XnAJs="
    end

    it "should sign using custom signature method" do
      options = {
        :service_id => 'MyService',
        :signature => CustomSignature
      }
      # debugger
      AuthHMAC.sign!(@request, "my-key-id", "secret", options)
      @request['Authorization'].should == "MyService my-key-id:/L4N1v1BZSHfAYkQjsvZn696D9c="
    end
  end
  
  describe "#sign!" do
    before(:each) do
      @get_request = Net::HTTP::Get.new("/")
      @put_request = Net::HTTP::Put.new("/path/to/put?foo=bar&bar=foo", 
        'content-type' => 'text/plain', 
        'content-md5' => 'blahblah', 
        'date' => "Thu, 10 Jul 2008 03:29:56 GMT")
       @store = mock('store')
      @store.stub!(:[]).and_return("")
      @authhmac = AuthHMAC.new(@store)
    end

    describe "default AuthHMAC with CanonicalString signature" do
      it "should add an Authorization header" do
        @authhmac.sign!(@get_request, 'key-id')
        @get_request.key?("Authorization").should be_true
      end
      
      it "should fetch the secret from the store" do
        @store.should_receive(:[]).with('key-id').and_return('secret')
        @authhmac.sign!(@get_request, 'key-id')
      end
      
      it "should prefix the Authorization Header with AuthHMAC" do
        @authhmac.sign!(@get_request, 'key-id')
        @get_request['Authorization'].should match(/^AuthHMAC /)
      end

      it "should include the key id as the first part of the Authorization header value" do
        @authhmac.sign!(@get_request, 'key-id')
        @get_request['Authorization'].should match(/^AuthHMAC key-id:/)
      end
      
      it "should include the base64 encoded HMAC signature as the last part of the header value" do
        @authhmac.sign!(@get_request, 'key-id')
        @get_request['Authorization'].should match(/:[A-Za-z0-9+\/]{26,28}[=]{0,2}$/)
      end
      
      it "should create a complete signature" do
        @store.should_receive(:[]).with('my-key-id').and_return('secret')
        @authhmac.sign!(@put_request, "my-key-id")
        @put_request['Authorization'].should == "AuthHMAC my-key-id:71wAJM4IIu/3o6lcqx/tw7XnAJs="
      end
    end

    describe "custom signatures" do
      before(:each) do
         @options = {
          :service_id => 'MyService',
          :signature => CustomSignature
        }
        @authhmac = AuthHMAC.new(@store, @options)
      end

      it "should prefix the Authorization header with custom service id" do
        @authhmac.sign!(@get_request, 'key-id')
        @get_request['Authorization'].should match(/^MyService /)
      end
      
      it "should create a complete signature using options" do
        @store.should_receive(:[]).with('my-key-id').and_return('secret')
        @authhmac.sign!(@put_request, "my-key-id")
        @put_request['Authorization'].should == "MyService my-key-id:/L4N1v1BZSHfAYkQjsvZn696D9c="
      end
    end
  end
  
  describe "authenticated?" do
    before(:each) do
      @credentials = YAML.load(File.read(File.join(File.dirname(__FILE__), 'fixtures', 'credentials.yml')))
      @authhmac = AuthHMAC.new(@credentials)
      @request = Net::HTTP::Get.new("/path/to/get?foo=bar&bar=foo", 'date' => "Thu, 10 Jul 2008 03:29:56 GMT")
    end
    
    it "should return false when there is no Authorization Header" do
      @authhmac.authenticated?(@request).should be_false
    end
    
    it "should return false when the Authorization value isn't prefixed with HMAC" do
      @request['Authorization'] = "id:secret"
      @authhmac.authenticated?(@request).should be_false
    end
    
    it "should return false when the access key id can't be found" do
      @request['Authorization'] = 'AuthHMAC missing-key:blah'
      @authhmac.authenticated?(@request).should be_false
    end    
    
    it "should return false when there is no hmac" do
      @request['Authorization'] = 'AuthHMAC missing-key:'
      @authhmac.authenticated?(@request).should be_false
    end
    
    it "should return false when the hmac doesn't match" do
      @request['Authorization'] = 'AuthHMAC access key 1:blah'
      @authhmac.authenticated?(@request).should be_false
    end
    
    it "should return false if the request was modified after signing" do
      @authhmac.sign!(@request, 'access key 1')
      @request.content_type = 'text/plain'
      @authhmac.authenticated?(@request).should be_false
    end
    
    it "should return true when the hmac does match" do
      @authhmac.sign!(@request, 'access key 1')
      @authhmac.authenticated?(@request).should be_true
    end

    describe "custom signatures" do
      before(:each) do
        @options = {
          :service_id => 'MyService',
          :signature => CustomSignature
        }
      end

      it "should return false for invalid service id" do
        @authhmac.sign!(@request, 'access key 1')
        AuthHMAC.new(@credentials, @options.except(:signature)).authenticated?(@request).should be_false
      end

      it "should return false for request using default CanonicalString signature" do
        @authhmac.sign!(@request, 'access key 1')
        AuthHMAC.new(@credentials, @options.except(:service_id)).authenticated?(@request).should be_false
      end
      
      it "should return true when valid" do
        @authhmac = AuthHMAC.new(@credentials, @options)
        @authhmac.sign!(@request, 'access key 1')
        @authhmac.authenticated?(@request).should be_true
      end
    end
  end
  
  describe "#sign! with YAML credentials" do
    before(:each) do
      @authhmac = AuthHMAC.new(YAML.load(File.read(File.join(File.dirname(__FILE__), 'fixtures', 'credentials.yml'))))
      @request = Net::HTTP::Get.new("/path/to/get?foo=bar&bar=foo", 'date' => "Thu, 10 Jul 2008 03:29:56 GMT")
    end
    
    it "should raise an argument error if credentials are missing" do
      lambda { @authhmac.sign!(@request, 'missing') }.should raise_error(ArgumentError)
    end
    
    it "should sign with the secret" do
      @authhmac.sign!(@request, "access key 1")
      @request['Authorization'].should == "AuthHMAC access key 1:ovwO0OBERuF3/uR3aowaUCkFMiE="
    end
    
    it "should sign with the other secret" do
      @authhmac.sign!(@request, "access key 2")
      @request['Authorization'].should == "AuthHMAC access key 2:vT010RQm4IZ6+UCVpK2/N0FLpLw="
    end
  end
  
  describe AuthHMAC::Headers do
    before(:each) do
      @authhmac = AuthHMAC.new(YAML.load(File.read(File.join(File.dirname(__FILE__), 'fixtures', 'credentials.yml'))))
    end
    
    it "should support Rack::Request objects" do
      rack_req = mock("MockRackRequest")
      headers = {
        'HTTP_AUTHORIZATION' => ["AuthHMAC access key 1:ovwO0OBERuF3/uR3aowaUCkFMiE="],
        'HTTP_DATE' => ['Thu, 10 Jul 2008 03:29:56 GMT']
      }
      rack_req.stub!(:env).and_return(headers)
      rack_req.stub!(:request_method).and_return('GET')
      rack_req.stub!(:path).and_return("/path/to/get?foo=bar&bar=foo")
      rack_req.stub!(:[]).and_return({'foo' => 'bar', 'bar' => 'foo'})
      @authhmac.authenticated?(rack_req).should be_true
    end
  end
  
  describe AuthHMAC::CanonicalString do
    it "should include the http verb when it is GET" do
      request = Net::HTTP::Get.new("/")
      AuthHMAC::CanonicalString.new(request).should match(/GET/)
    end
    
    it "should include the http verb when it is POST" do
      request = Net::HTTP::Post.new("/")
      AuthHMAC::CanonicalString.new(request).should match(/POST/)
    end
    
    it "should include the content-type" do
      request = Net::HTTP::Put.new("/", {'Content-Type' => 'application/xml'})
      AuthHMAC::CanonicalString.new(request).should match(/application\/xml/)
    end
    
    it "should include the content-type even if the case is messed up" do
      request = Net::HTTP::Put.new("/", {'cOntent-type' => 'text/html'})
      AuthHMAC::CanonicalString.new(request).should match(/text\/html/)
    end
    
    it "should include the content-md5" do
      request = Net::HTTP::Put.new("/", {'Content-MD5' => 'skwkend'})
      AuthHMAC::CanonicalString.new(request).should match(/skwkend/)
    end    
    
    it "should include the content-md5 even if the case is messed up" do
      request = Net::HTTP::Put.new("/", {'content-md5' => 'adsada'})
      AuthHMAC::CanonicalString.new(request).should match(/adsada/)
    end
    
    it "should include the date" do
      date = Time.now.httpdate
      request = Net::HTTP::Put.new("/", {'Date' => date})
      AuthHMAC::CanonicalString.new(request).should match(/#{date}/)
    end
    
    it "should include the request path" do
      request = Net::HTTP::Get.new("/path/to/file")
      AuthHMAC::CanonicalString.new(request).should match(/\/path\/to\/file[^?]?/)
    end
    
    it "should ignore the query string of the request path" do
      request = Net::HTTP::Get.new("/other/path/to/file?query=foo")
      AuthHMAC::CanonicalString.new(request).should match(/\/other\/path\/to\/file[^?]?/)
    end
    
    it "should build the correct string" do
      date = Time.now.httpdate
      request = Net::HTTP::Put.new("/path/to/put?foo=bar&bar=foo", 
                                    'content-type' => 'text/plain', 
                                    'content-md5' => 'blahblah', 
                                    'date' => date)
      AuthHMAC::CanonicalString.new(request).should == "PUT\ntext/plain\nblahblah\n#{date}\n/path/to/put"                                            
    end
    
    it "should build the correct string when some elements are missing" do
      date = Time.now.httpdate
      request = Net::HTTP::Get.new("/path/to/get?foo=bar&bar=foo",
                                    'date' => date)
      AuthHMAC::CanonicalString.new(request).should == "GET\n\n\n#{date}\n/path/to/get"
    end
  end
end
