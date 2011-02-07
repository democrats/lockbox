# This script requires a Lockbox partner to be created as follows in script/console:
# p = Partner.createi!{ "password" => "password", "password_confirmation" => "password", "name"=>"user", "phone_number"=>"5555555555", "organization"=>"test", "email"=>"a@a.com" } 
# p.confirmed = true; p.api_key = 12345; p.max_requests = nil; p.save! 

require 'rubygems'
gem 'dnclabs-auth-hmac'
require 'httpotato'
require 'auth-hmac'

class HmacRequest

  def self.config
    {'host' => 'localhost:4567', 'hmac_id' => 'test-user', 'hmac_secret' => '12345'}
  end  

  include HTTPotato
  format :html
  base_uri self.config['host']

  def self.test_get
    authenticated_get("/test")
  end

  def self.test_post
    authenticated_post("/test", :body => "some post body data")
  end

  def self.authenticated_post(url, options = {})
    options_merged = options.merge({:headers => {"CONTENT-TYPE" => "application/x-www-form-urlencoded"}, :hmac => {:id => config['hmac_id'], :secret => config['hmac_secret']}})
    begin
      post url, options_merged
    rescue HTTPotato::ParseError
      return {}
    end
  end

  def self.authenticated_put(url, options = {})
    begin
      put url, options.merge({:headers => {"CONTENT-TYPE" => "application/x-www-form-urlencoded"}, :hmac => {:id => config['hmac_id'], :secret => config['hmac_secret']}})
    rescue HTTPotato::ParseError
      return {}
    end
  end
  
  def self.authenticated_get(url, options = {})
    begin
      get url, options.merge({:hmac => {:id => config['hmac_id'], :secret => config['hmac_secret']}})
    rescue HTTPotato::ParseError
      return {}
    end
  end
  
end

puts HmacRequest.test_get
puts HmacRequest.test_post

