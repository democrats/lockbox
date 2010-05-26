require 'spec_helper'

describe PartnerSessionsController do
  include HelperMethods

  context "Show" do
    subject do
      get :new
      response
    end
    
    it { should be_success }
  end
  
  context "Create" do
    let(:partner) { Factory(:partner) }

    context "Valid" do
      subject do
        post :create, :partner_session => { :email => partner.email, 
                                         :password => partner.password }
        response.stubs(:response).returns(response)
        response
      end
      
      it { should redirect_to partners_path }
      it { should set_the_flash.to "You have been signed in" }
    end
    
    context "Does not exist" do
      subject do
        post :create, :partner_session => { :email => "x_#{partner.email}",
                                         :password => partner.password }
        response.stubs(:response).returns(response)
        response
      end
      
      it { should render_template :new }
      it { should set_the_flash.to "Email doesn't exist or bad Pasword" }
    end

    context "Bad Password" do
      subject do
        post :create, :partner_session => { :email => partner.email, 
                                         :password => "x_#{partner.password}" }
        response.stubs(:response).returns(response)
        response
      end
      
      it { should render_template :new }
      it { should set_the_flash.to "Email doesn't exist or bad Pasword" }
    end

  end
  
  context "Destroy" do
    let(:current_partner_session) { mock("partner_session") }

    before do
      activate_authlogic
      partner = Factory(:partner)
      current_partner_session.stubs(:record => partner)
      current_partner_session.stubs(:destroy => true)
      PartnerSession.stubs(:find => current_partner_session)
      session_for(partner)
    end
    
    it "should set the flash" do
      delete :destroy
      should set_the_flash.to "You have been logged out"
    end
    
    it "should redirect to /" do
      delete :destroy
      response.should redirect_to root_path
    end
    
    it "should destory the session" do
      current_partner_session.expects(:destroy)
      delete :destroy
    end
  end

end