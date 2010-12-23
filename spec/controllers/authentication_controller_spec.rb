require 'spec_helper'

describe AuthenticationController do
  integrate_views

  context "with an existing partner" do
    before(:each) do
      @partner = Factory(:partner)
    end
    subject { @partner }
    
    it "should return 200 for successful authentication" do
      get :show, :id => subject.api_key
      response.should be_success
    end

    it "should return the API key in a header" do
      get :show, :id => subject.api_key
      response.headers['X-LockBox-API-Key'].should == subject.api_key
    end
    
    it "should return 401 for unsuccessful authentication" do
      get :show, :id => 'potato'
      response.should_not be_success
      response.status.should =~ /401/
    end
    
    context "using HMAC authentication" do

      context "on a GET request" do
        subject { Factory(:partner) }

        before do
          subject.stubs(:api_key).returns('daad465deb7718a5d0db99345be41e3a1ea0de6d')
          Partner.stubs(:find_by_slug).returns(subject)
          Partner.stubs(:find_by_api_key).returns(subject)

          Time.stubs(:fifteen_minutes_ago).returns(Time.parse("2010-05-10 16:15:00 EDT"))
          Time.stubs(:now).returns(Time.parse("2010-05-10 16:30:00 EDT"))
          {'X-Referer-Method' => 'GET', 'X-Referer-Date' => [Time.now.httpdate], 'X-Referer-Authorization' => ['AuthHMAC cherry tree cutters:GurpT6GfwItXF3Co4Ut1a3I+3iI='], 'Referer' => 'http://example.org/api/some_controller/some_action'}.each_pair do |e,value|
            request.env[e] = value
          end
        end
        
        it "should return 200 with valid HMAC credentials" do
          get :show, :id => 'hmac'
          response.should be_success
        end

        it "should return 200 with valid HMAC credentials and a bad referer date format" do
          request.env['HTTP_DATE'] = Time.now.rfc2822
          request.env['X-Referer-Date'] = Time.now.rfc2822
          #request.env["X-Referer-Authorization"] =  "AuthHMAC cherry tree cutters:ZUiJgjYr6w0/gTtYT+v39rGpS3Q="
          request.env["X-Referer-Authorization"] =  "AuthHMAC cherry tree cutters:GasKdSrREUednKGC9RTTLydvcDA="
          get :show, :id => 'hmac'
          response.should be_success
        end

        it "should return 401 with a valid HMAC that is too old" do
          request.env['X-Referer-Date'] = Time.fifteen_minutes_ago.httpdate
          request.env['X-Referer-Authorization'] = 'AuthHMAC cherry tree cutters:2hYdDX0C74Fr9CBVy6ZYEUIWo5c='
          get :show, :id => 'hmac'
          response.should_not be_success
          response.status.should =~ /401/
        end

        it "should return 401 with invalid HMAC credentials" do
          request.env['X-Referer-Authorization'] = ['AuthHMAC foo:bar']
          get :show, :id => 'hmac'
          response.should_not be_success
          response.status.should =~ /401/
        end

      end

      context "on a POST request" do
        subject { Factory(:partner) }

        before do
          subject.stubs(:api_key).returns('daad465deb7718a5d0db99345be41e3a1ea0de6d')
           Partner.stubs(:find_by_slug).returns(subject)
           Partner.stubs(:find_by_api_key).returns(subject)
           Time.stubs(:fifteen_minutes_ago).returns(Time.parse("2010-05-10 16:15:00 EDT"))
           Time.stubs(:now).returns(Time.parse("2010-05-10 16:30:00 EDT"))
           {'X-Referer-Method' => 'GET', 'X-Referer-Date' => [Time.now.httpdate], 'X-Referer-Authorization' => ['AuthHMAC cherry tree cutters:e1ADdHE14mG8jb8G64ax2VflT6k='], 'Referer' => 'http://example.org/api/some_controller/some_action'}.each_pair do |e,value|
             request.env[e] = value
          end
        end

        it "should return 200 with valid HMAC credentials from a POST with no body" do
          request.env['X-Referer-Method'] = 'POST'
          request.env['X-Referer-Content-Type'] = 'application/x-www-form-urlencoded'
          get :show, :id => 'hmac'
          response.should be_success
        end

        it "should return 401 on a valid HMAC digest from a POST that is too old" do
          request.env['X-Referer-Method'] = 'POST'
          request.env['X-Referer-Content-Type'] = 'application/x-www-form-urlencoded'
          request.env['X-Referer-Date'] = Time.fifteen_minutes_ago.httpdate
          request.env['X-Referer-Authorization'] = 'AuthHMAC cherry tree cutters:gzB20BqWINwJpO/jJdphbFgCJLE='
          get :show, :id => 'hmac'
          response.should_not be_success
          response.status.should =~ /401/
        end

        it "should return 200 with valid HMAC credentials from a POST with a body" do
          request.env['X-Referer-Method'] = 'POST'
          request.env['X-Referer-Content-Type'] = 'application/x-www-form-urlencoded'
          request.env['X-Referer-Content-MD5'] = '7677da04ebf69f3c5ad4bfaf6528e1d7'
          request.env['X-Referer-Authorization'] = ['AuthHMAC cherry tree cutters:WCHbGQJZfAyiU65kyulX3E2D6bk=']
          get :show, :id => 'hmac'
          response.should be_success
        end

        it "should return 401 with valid HMAC credentials from a POST with no Content-Type header" do
          request.env['X-Referer-Method'] = 'POST'
          get :show, :id => 'hmac'
          response.status.should =~ /401/
        end

      end
    
    end
    
    it "should increment current_request_count for this partner after successful auth" do
      count = subject.current_request_count
      get :show, :id => subject.api_key
      subject.current_request_count.should == count+1
    end
    
    it "should return 420 once max_requests has been reached" do
      # 420 is the code the Twitter rate limiting API uses
      subject.requests_remaining.times do
        subject.increment_request_count
      end
      get :show, :id => subject.api_key
      response.should_not be_success
      response.status.should =~ /420/
    end
    
    it "should include an error message in the body when rate limited" do
      subject.requests_remaining.times do
        subject.increment_request_count
      end
      get :show, :id => subject.api_key
      response.body.should =~ /Too many requests/
    end
    
    it "should return Cache-Control header after successful auth" do
      get :show, :id => subject.api_key
      expected_cc_header = ['public', 'no-cache']
      response.headers['Cache-Control'].split(/,\s*/).sort.should eql(expected_cc_header.sort)
    end
    
    it "should return Twitter-style rate limit headers after successful auth" do
      # these headers are documented here: http://apiwiki.twitter.com/Rate-limiting
      get :show, :id => subject.api_key
      expected_rl_headers = {
        'X-RateLimit-Limit' => subject.max_requests,
        'X-RateLimit-Remaining' => subject.requests_remaining,
        'X-RateLimit-Reset' => subject.max_requests_reset_time,
      }
      rl_headers_received = Hash.new
      expected_rl_headers.keys.map { |header|
        rl_headers_received[header] = @response.headers[header].to_i
      }
      rl_headers_received.should eql(expected_rl_headers)
    end

    context "with a protected application" do
      before(:each) do
        @pa = Factory(:protected_application)
        @partner.protected_applications.push(@pa)
        @partner.save!
      end

      it "should allow access to the application name" do
        get :show, {:id => @partner.api_key, :application_name => @pa.name}
        response.should be_success
      end

      it "should not allow access to other application names" do
        get :show, {:id => @partner.api_key, :application_name => 'crazycrazy'}
        response.should_not be_success
        response.status.should =~ /401/
      end

      it "should allow access with no application name" do
        get :show, :id => @partner.api_key
        response.should be_success
      end
    end

  end

  context "with a partner that has no max requests" do
    subject { Factory(:partner, :max_requests => nil) }

    it "should allow access" do
      get :show, :id => subject.api_key
      response.should be_success
    end
    
    it "should not return rate limit headers after successful auth" do
      get :show, :id => subject.api_key
      response.headers.each_key do |header|
        header.should_not =~ /^X-RateLimit-/
      end
    end
    
    it "should return Cache-Control header after successful auth" do
      get :show, :id => subject.api_key
      expected_cc_header = ['public', "max-age=#{subject.max_response_cache_time}", 'must-revalidate']
      response.headers['Cache-Control'].split(/,\s*/).sort.should eql(expected_cc_header.sort)
    end
    
  end


end
