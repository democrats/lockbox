require 'spec_helper'

describe Admin::PartnersController do
  # include Rack::Test::Methods
  include HelperMethods
  
  context "an admin" do
    before do
      @partner = Factory(:partner)
      admin_login
    end
    
    it "should be able to get index" do
      get :index
      assert_response :success
    end

    it "should be able to show a partner" do
      get :show, :id => @partner.id
      assert_response :success
    end

    it "should be able to get edit page for partner" do
      get :edit, :id => @partner.id
      assert_response :success
    end

    it "should be able to destroy a partner" do
      assert Partner.find(@partner.id)
      delete :destroy, :id => @partner.id
      assert_redirected_to admin_partners_path
      assert_raise(ActiveRecord::RecordNotFound) {  Partner.find(@partner.id) }
    end

    it "should not be able to destroy a partner" do
      Partner.any_instance.stubs(:destroy).returns(false)
      assert Partner.find(@partner.id)
      delete :destroy, :id => @partner.id
      assert_redirected_to admin_partners_path
      assert Partner.find(@partner.id)
    end

    it "should be able to update a partner" do
      put :update, :id => @partner.id, :partner => Factory.attributes_for(:partner, :name => 'crazyname', :max_requests => 1234, 
        :password => nil, :password_confirmation => nil)
      assert_equal("crazyname", @partner.reload.name)
      assert_equal(1234, @partner.max_requests)
    end


    it "should not be able to update an invalud partner" do
      partner_email = @partner.email
      partner_max_requests = @partner.max_requests
      put :update, :id => @partner.id, :partner => Factory.attributes_for(:partner, :email => 'invalidemail', :max_requests => 1234,
        :password => nil, :password_confirmation => nil)
      assert_equal(partner_email, @partner.reload.email)
      assert_equal(partner_max_requests, @partner.max_requests)
    end
    
  end
  

  
end