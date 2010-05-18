require 'test_helper'

class ConfirmationControllerTest < ActionController::TestCase

  context "Update" do
    setup do
      @perishable_token = "1234"
      @partner = Factory.build(:partner, :confirmed => false)
      @partner.stubs(:save).returns(true)
      Partner.stubs(:find_by_perishable_token!).returns(@partner)
      PartnerSession.stubs(:create)
      get :update, :perishable_token => @perishable_token
    end
    
    should_redirect_to("root_path") { root_path }
    should "confirm the partner" do
      assert @partner.confirmed?
      assert_received(@partner, :save)
    end
    should "find by the perishable token" do
      assert_received(Partner, :find_by_perishable_token!) { |expect| expect.with(@perishable_token) }
    end
    should "log the partner in" do
      assert_received(PartnerSession, :create) { |expect| expect.with(@partner) }
    end
  end
end
