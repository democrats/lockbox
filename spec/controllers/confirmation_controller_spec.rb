require 'spec_helper'

describe ConfirmationController do

  context "Update" do
    let(:partner) { Factory.build(:partner, :confirmed => false) }
    let(:perishable_token) { "1234" }
    
    before do
      partner.stubs(:save).returns(true)
      Partner.stubs(:find_by_perishable_token!).returns(partner)
      PartnerSession.stubs(:create)
    end
    
    it "should redirect to /" do
      get :update, :perishable_token => perishable_token
      response.should redirect_to(root_path)
    end
    
    it "should confirm the partner" do
      partner.expects :save
      get :update, :perishable_token => perishable_token
      partner.should be_confirmed
    end
    
    it "should find by the perishable token" do
      Partner.expects(:find_by_perishable_token!).with(perishable_token).returns(partner)
      get :update, :perishable_token => perishable_token
    end
    
    it "should log the partner in" do
      PartnerSession.expects(:create).with(partner)
      get :update, :perishable_token => perishable_token
    end
  end
end
