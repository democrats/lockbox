require 'test_helper'

class Admin::PartnersControllerTest < ActionController::TestCase

  context "an admin" do
    setup do
      @partner = Factory(:partner)
      admin_login
    end
    
    should "be able to get index" do
      get :index
      assert_response :success
    end

    should "be able to show a partner" do
      get :show, :id => @partner.id
      assert_response :success
    end

    should "be able to get edit page for partner" do
      get :edit, :id => @partner.id
      assert_response :success
    end

    should "be able to destroy a partner" do
      assert Partner.find(@partner.id)
      delete :destroy, :id => @partner.id
      assert_redirected_to admin_partners_path
      assert_raise(ActiveRecord::RecordNotFound) {  Partner.find(@partner.id) }
    end

    should "be able to update a partner" do
      put :update, :id => @partner.id, :record => Factory.attributes_for(:partner, :name => 'crazyname', :max_requests => 1234, 
        :password => nil, :password_confirmation => nil)
      assert_equal("crazyname", @partner.reload.name)
      assert_equal(1234, @partner.max_requests)
    end
    
    should "be able to get new page" do
      get :new
      assert_response :success
    end
    
    should "be able to create a new partner" do
      count = Partner.count
      post :create, :record => {:name => "crazyname", :organization => @partner.organization, :phone_number => @partner.phone_number, :email => "something@somewhere.com", :max_requests => "1234", :password => 'potato', :password_confirmation => 'potato'}
      assert_equal(count + 1, Partner.count)
      assert Partner.find_by_name("crazyname")
      assert Partner.find_by_email("something@somewhere.com")
    end

  end

end