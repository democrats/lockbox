require 'spec_helper'

describe Admin::ProtectedApplicationsController do
  # include Rack::Test::Methods
  include HelperMethods

  context "an admin" do
    before do
      @protected_application = Factory(:protected_application)
      admin_login
    end

    it "should be able to get index" do
      get :index
      assert_response :success
    end

    it "should be able to show a protected application" do
      get :show, :id => @protected_application.id
      assert_response :success
    end

    it "should be able to get edit page for protected application" do
      get :edit, :id => @protected_application.id
      assert_response :success
    end

    it "should be able to destroy a protected application" do
      assert ProtectedApplication.find(@protected_application.id)
      delete :destroy, :id => @protected_application.id
      assert_redirected_to admin_protected_applications_path
      assert_raise(ActiveRecord::RecordNotFound) {  Partner.find(@protected_application.id) }
    end

    it "should be able to update a protected application" do
      put :update, :id => @protected_application.id, :protected_application => Factory.attributes_for(:protected_application, :name => 'crazyname')
      assert_equal("crazyname", @protected_application.reload.name)
    end

    it "should be able to get new page" do
      get :new
      assert_response :success
    end

    it "should be able to create a new protected application" do
      count = ProtectedApplication.count
      post :create, :protected_application => {:name => "crazyname", :description => 'foo'}
      assert_equal(count + 1, ProtectedApplication.count)
      assert ProtectedApplication.find_by_name("crazyname")
    end
  end



end