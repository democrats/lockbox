require 'spec_helper'

describe 'PartnersController' do
  include Rack::Test::Methods
  
  context "Index" do
    before do
      stubbed_session_for(:partner)
      get :index
    end
    
    it { should_redirect_to("partner path") { partner_path(@partner.api_key) } }

  end

  context "Create" do
    before do
      @partner = Factory(:partner)
      @partner.stubs(:id).returns(1)
      PartnerMailer.stubs(:deliver_confirmation)
    end
    
    context "Valid" do
      before do
        @partner.stubs(:save).returns(true)
        Partner.stubs(:new).returns(@partner)
        post :create, :partner => Factory.attributes_for(:partner)
      end
      
      it { should_redirect_to("partner page") { partner_path(@partner.api_key) } }
      
      it "should deliver the cofirmation mail" do
        assert_received(PartnerMailer, :deliver_confirmation) { |expect| expect.with(@partner) }
      end
    end
    
    context "Invalid" do
      before do
        @partner.stubs(:save).returns(false)
        Partner.stubs(:new).returns(@partner)
        post :create, :partner => { }
      end
    
      it { should_render_template :new }
      
      it "should not deliver the confirmation mail" do
        assert_not_received(PartnerMailer, :deliver_confirmation)
      end
    end
    
  end

  context "New" do
    before do
      get :new
    end
    
    it { should_respond_with :success }
    it { should_assign_to :partner }
  end
  
  context "Show" do
    before do
      stubbed_session_for(:partner)
      get :show,  :id => @partner.api_key
    end
    
    it { should_respond_with :success }
    it { should_assign_to :partner }
  end

  context "API Show" do
    before do
      stubbed_session_for(:partner)
    end
    context "json" do
      before do
        get :show,  :id => @partner.api_key, :format => 'json'
      end

      it { should_respond_with :success }
      it { should_assign_to :partner }
    end

    context "jsonp" do
      before do
        get :show,  :id => @partner.api_key, :format => 'jsonp', :variable => 'foo', :callback => 'bar'
      end

      it { should_respond_with :success }
      it { should_assign_to :partner }
    end

  end
  
  context "Edit" do
    before do
      stubbed_session_for(:partner)
      get :edit, :id => @partner.api_key      
    end
    
    it { should_respond_with :success }
    it { should_assign_to :partner }
  end
  
  context "Update" do
    before do
      @partner = Factory(:partner)
    end
    
    context "Valid" do
      before do
        @partner.stubs(:save).returns(true)
        stubbed_session_for(@partner)
        put :update, :partner => { }, :id => @partner.api_key
      end
      
      it { should_redirect_to("partner path") { partner_path(@partner.api_key) } }
    end
    
    context "Invalid" do
      before do
        @partner.stubs(:save).returns(false)
        stubbed_session_for(@partner)
        Partner.stubs(:find_by_api_key).returns(@partner)
        put :update, :partner => { }, :id => @partner.api_key 
      end
      
      it { should_render_template :edit }
    end
  end
end