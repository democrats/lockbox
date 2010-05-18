require 'test_helper'

class PartnerSessionsControllerTest < ActionController::TestCase

  context "Show" do
    setup do
      get :new
    end
    
    should_respond_with(:success)
  end
  
  context "Create" do
    setup do
      @partner = Factory(:partner)
    end

    context "Valid" do
      setup do
        post :create, :partner_session => { :email => @partner.email, 
                                         :password => @partner.password }
      end
      should_redirect_to("partners path") { partners_path }
      should_set_the_flash_to "You have been signed in"
    end
    
    context "Does not exist" do
      setup do
        post :create, :partner_session => { :email => "x_#{@partner.email}",
                                         :password => @partner.password }
      end
      should_render_template :new
      should_set_the_flash_to "Email doesn't exist or bad Pasword"
    end

    context "Bad Password" do
      setup do
        post :create, :partner_session => { :email => @partner.email, 
                                         :password => "x_#{@partner.password}" }
      end
      should_render_template :new
      should_set_the_flash_to "Email doesn't exist or bad Pasword"
    end

  end
  
  context "Destroy" do
    setup do
      activate_authlogic
      @partner = Factory(:partner)
      @current_partner_session = mock("partner_session")
      @current_partner_session.stubs(:record => @partner)
      @current_partner_session.stubs(:destroy => true)
      PartnerSession.stubs(:find => @current_partner_session)
      session_for(@partner)
      
      delete :destroy
    end
    
    should_set_the_flash_to "You have been logged out"
    should_redirect_to("root_path") { root_path }
    should "destory the session" do
      assert_received(@current_partner_session, :destroy)
    end
  end

end