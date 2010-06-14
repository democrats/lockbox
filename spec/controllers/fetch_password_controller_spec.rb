require 'spec_helper'

describe FetchPasswordController do
  include HelperMethods
  
  context "Index" do
    let(:partner) { Partner.new }
    
    before do
      Partner.stubs(:new).returns(partner)
    end
    
    it "should respond with successful status" do
      get :index
      should respond_with :success
    end
    
    it "should create a new instance of Partner" do
      Partner.expects(:new)
      get :index
    end
  end
  
  context "Show" do
    let(:partner) { Factory.build(:partner) }
    let(:partner_session) { PartnerSession.new }
    let(:perishable_token) { "1234" }
    
    before do
      Partner.stubs(:find_by_perishable_token!).returns(partner)
    end
    
    context "Authenticates" do
      before do
        partner_session.stubs(:save).returns(true)
        PartnerSession.stubs(:new).returns(partner_session)
        get :show, :id => perishable_token
      end
      
      it { should respond_with :success }
    end
    
    context "Does not authenticate" do
      before do
        partner_session.stubs(:save).returns(false)
        PartnerSession.stubs(:new).returns(partner_session)
        get :show, :id => perishable_token
      end
      
      its(:response) { should redirect_to fetch_password_index_path }
    end
  end
  
  context "Create" do
    context "Valid" do
      let(:partner) { Factory.build(:partner) }
      
      before do
        Partner.stubs(:find_by_email).returns(partner)
        PartnerMailer.stubs(:deliver_fetch_password)
      end
      
      it "should redirect to /" do
        post :create, :partner => { :email => partner.email }
        response.should redirect_to root_path
      end
      
      it "should find a partner by the email" do
        Partner.expects(:find_by_email).with(partner.email)
        post :create, :partner => { :email => partner.email }
      end
      
      it "should deliver an email to the partner" do
        PartnerMailer.expects(:deliver_fetch_password).with(partner)
        post :create, :partner => { :email => partner.email }
      end
    end
  
    context "Invalid" do
      let(:partner) { Partner.new(:email => "bademail@test.com") }
      
      before do
        Partner.stubs(:find_by_email)
        PartnerMailer.stubs(:deliver_fetch_password)
      end
      
      it "should render in the index template" do
        post :create, :partner => { :email => partner.email }
        response.should render_template(:index)
      end
      
      it "should assign a new instance of Partner to partner" do
        post :create, :partner => { :email => partner.email }
        assigns(:partner).should be_new_record
      end
      
      it "should try to find a partner by the email" do
        Partner.expects(:find_by_email).with(partner.email)
        post :create, :partner => { :email => partner.email }
      end
      
      it "should not deliver an email" do
        PartnerMailer.expects(:deliver_fetch_password).never
        post :create, :partner => { :email => partner.email }
      end
    end
  end

  context "Update" do
    before do
      stubbed_session_for(:partner)
    end
    
    context "Valid" do
      let(:password) { "goodpassword" }
      let(:partner) { @partner }
      
      before do
        partner.stubs(:save).returns(true)
        FetchPasswordController.any_instance.stubs(:current_partner).returns(partner)
      end
      
      it "should redirect to /" do
        put :update, :partner => { :password => password, :password_confirmation => password }
        response.should redirect_to root_path
      end
      
      it "should attempt to save the record " do
        partner.expects(:save)
        put :update, :partner => { :password => password, :password_confirmation => password }
      end
    end
    
    context "Invalid" do
      let(:password) { "badpassword" }
      let(:partner) { @partner }
      
      before do
        partner.stubs(:save).returns(false)
        FetchPasswordController.any_instance.stubs(:current_partner).returns(partner)
      end
      
      it "should render the show template" do
        put :update, :partner => { :password => password }
        response.should render_template :show
      end
      
      it "should attempt to save the record " do
        partner.expects(:save)
        put :update, :partner => { :password => password }
      end
    end
  end

end