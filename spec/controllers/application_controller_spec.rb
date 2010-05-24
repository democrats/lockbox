require 'spec_helper'

describe ApplicationController do

  context "an instantiated controller" do

    context "rendering jsonp" do
      it "should pass the json straight through with no options" do
        subject.stubs(:params).returns({})
        subject.expects(:render).with({:text => 'foo'}).returns(true)
        subject.render_jsonp('foo')
      end

      it "should return jsonp with variable assignment" do
        subject.stubs(:params).returns({:variable => 'var'})
        subject.expects(:render).with({:text => 'var var = foo;'}).returns(true)
        subject.render_jsonp('foo')
      end

      it "should return jsonp with callback" do
        subject.stubs(:params).returns({ :callback => 'callback'})
        subject.expects(:render).with({:text => 'callback(foo);'}).returns(true)
        subject.render_jsonp('foo')
      end

      it "should return jsonp with variable assignment and callback" do
        subject.stubs(:params).returns({:variable => 'var', :callback => 'callback'})
        subject.expects(:render).with({:text => "var var = foo;\ncallback(var);"}).returns(true)
        subject.render_jsonp('foo')
      end

    end
  end


  context "Test Exception Notifier" do

    it "raise exception when passed proper params" do
      lambda { get :test_exception_notification, :id => 'blowup' }.should raise_exception(RuntimeError)
    end

    context "without proper params" do

      before do
        get :test_exception_notification
      end

      it "say access denied" do
        @response.body.should == "Access Denied"
      end

    end


  end



end