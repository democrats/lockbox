require 'test_helper'

class PartnersControllerTest < ActionController::TestCase

  context "Create" do
    setup do
      @partner = Factory(:partner)
      @partner.stubs(:id).returns(1)
      PartnerMailer.stubs(:deliver_confirmation)
    end
    
    context "Valid" do
      setup do
        @partner.stubs(:save).returns(true)
        Partner.stubs(:new).returns(@partner)
        post :create, :partner => Factory.attributes_for(:partner)
      end
      
      should_redirect_to("partner page") { partner_path(@partner.api_key) }
      should "deliver the cofirmation mail" do
        assert_received(PartnerMailer, :deliver_confirmation) { |expect| expect.with(@partner) }
      end
    end
    
    context "Invalid" do
      setup do
        @partner.stubs(:save).returns(false)
        Partner.stubs(:new).returns(@partner)
        post :create, :partner => { }
      end
    
      should_render_template :new
      should "not deliver the confirmation mail" do
        assert_not_received(PartnerMailer, :deliver_confirmation)
      end
    end
    
  end

  context "New" do
    setup do
      get :new
    end
    
    should_respond_with :success
    should_assign_to :partner
  end
  
  context "Show" do
    setup do
      stubbed_session_for(:partner)
      get :show,  :id => @partner.api_key
    end
    
    should_respond_with :success
    should_assign_to :partner
  end

  context "API Show" do
    setup do
      stubbed_session_for(:partner)
    end
    context "json" do
      setup do
        get :show,  :id => @partner.api_key, :format => 'json'
      end

      should_respond_with :success
      should_assign_to :partner
    end

    context "jsonp" do
      setup do
        get :show,  :id => @partner.api_key, :format => 'jsonp', :variable => 'foo', :function => 'bar'
      end

      should_respond_with :success
      should_assign_to :partner
    end

  end
  
  context "Edit" do
    setup do
      stubbed_session_for(:partner)
      get :edit, :id => @partner.api_key      
    end
    
    should_respond_with :success
    should_assign_to :partner
  end
  
  context "Update" do
    setup do
      @partner = Factory(:partner)
    end
    
    context "Valid" do
      setup do
        @partner.stubs(:save).returns(true)
        stubbed_session_for(@partner)
        put :update, :partner => { }, :id => @partner.api_key
      end
      
      should_redirect_to("partner path") { partner_path(@partner.api_key) }
    end
    
    context "Invalid" do
      setup do
        @partner.stubs(:save).returns(false)
        stubbed_session_for(@partner)
        Partner.stubs(:find_by_api_key).returns(@partner)
        put :update, :partner => { }, :id => @partner.api_key 
      end
      
      should_render_template :edit
    end
  end
  
end
