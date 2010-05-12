require 'test_helper'

class ApplicationControllerUnitTest < Test::Unit::TestCase

  context "an instantiated controller" do
    setup do
      @controller = ApplicationController.new
    end

    context "rendering jsonp" do
      should "pass the json straight through with no options" do
        @controller.stubs(:params).returns({})
        @controller.expects(:render).with({:text => 'foo'}).returns(true)
        @controller.render_jsonp('foo')
      end

      should "jsonp with variable assignment" do
        @controller.stubs(:params).returns({:variable => 'var'})
        @controller.expects(:render).with({:text => 'var var = foo;'}).returns(true)
        @controller.render_jsonp('foo')
      end

     should "jsonp with callback" do
        @controller.stubs(:params).returns({ :callback => 'callback'})
        @controller.expects(:render).with({:text => 'callback(foo);'}).returns(true)
        @controller.render_jsonp('foo')
      end

      should "jsonp with variable assignment and callback" do
        @controller.stubs(:params).returns({:variable => 'var', :callback => 'callback'})
        @controller.expects(:render).with({:text => "var var = foo;\ncallback(var);"}).returns(true)
        @controller.render_jsonp('foo')
      end
    end
  end


  
end