require 'test_helper'

class FetchPasswordControllerTest < ActionController::TestCase

  context "Index" do
    setup do
      @partner = Partner.new
      Partner.stubs(:new).returns(@partner)
      get :index
    end
    
    should_respond_with(:success)
    should "create a new instance of Partner" do
      assert_received(Partner, :new)
    end
  end
  
  context "Show" do
    setup do
      @partner          = Factory.build(:partner)
      @partner_session  = PartnerSession.new
      @perishable_token = "1234"
      Partner.stubs(:find_by_perishable_token!).returns(@partner)
    end
    
    context "Authenticates" do
      setup do
        @partner_session.stubs(:save).returns(true)
        PartnerSession.stubs(:new).returns(@partner_session)
        get :show, :id => @perishable_token
      end
      
      should_respond_with(:success)
    end
    
    context "Does not authenticate" do
      setup do
        @partner_session.stubs(:save).returns(false)
        PartnerSession.stubs(:new).returns(@partner_session)
        get :show, :id => @perishable_token
      end
      
      should_redirect_to("fetch_password_index_path") { fetch_password_index_path }
    end
  end
  
  context "Create" do
    context "Valid" do
      setup do
        @partner = Factory.build(:partner)
        Partner.stubs(:find_by_email).returns(@partner)
        PartnerMailer.stubs(:deliver_fetch_password)
        post :create, :partner => { :email => @partner.email }
      end
      
      should_redirect_to("root_path") { root_path }
      should "find a partner by the email" do
        assert_received(Partner, :find_by_email) { |expect| expect.with(@partner.email) }
      end
      should "deliver an email to the partner" do
        assert_received(PartnerMailer, :deliver_fetch_password) { |expect| expect.with(@partner) }
      end
    end
  
    context "Invalid" do
      setup do
        @partner = Partner.new(:email => "bademail@test.com")
        Partner.stubs(:find_by_email).returns(nil)
        PartnerMailer.stubs(:deliver_fetch_password)
        post :create, :partner => { :email => @partner.email }
      end
      
      should_render_template(:index)
      should "assign a new instance of Partner to @partner" do
        assert assigns(:partner).new_record?
      end
      should "try to find a partner by the email" do
        assert_received(Partner, :find_by_email) { |expect| expect.with(@partner.email) }
      end
      should "not deliver an email" do
        assert_not_received(PartnerMailer, :deliver_fetch_password)
      end
    end
  end

  context "Update" do
    setup do
      stubbed_session_for(:partner)
      @partner = Factory.build(:partner)
    end
    
    context "Valid" do
      setup do
        @partner.stubs(:save).returns(true)
        @password = "goodpassword"
        FetchPasswordController.any_instance.stubs(:current_partner).returns(@partner)
        put :update, :partner => { :password => @password, :password_confirmation => @password }
      end
      
      should_redirect_to("root_path") { root_path }
      should "attempt to save the record " do
        assert_received(@partner, :save)
      end
    end
    
    context "Invalid" do
      setup do
        @partner.stubs(:save).returns(false)
        @password = "badpassword"
        FetchPasswordController.any_instance.stubs(:current_partner).returns(@partner)
        put :update, :partner => { :password => @password }
      end
      
      should_render_template(:show)
      should "attempt to save the record " do
        assert_received(@partner, :save)
      end
    end
  end

end