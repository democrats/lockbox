require 'test_helper'

class PartnerMailerTest < ActionMailer::TestCase

  context "Confirmation Email" do
    setup do
      @partner = Factory.build(:partner)
      @partner.stubs(:perishable_token).returns.returns("1234")
      @email = PartnerMailer.create_confirmation(@partner)
    end
    
    should "deliver to the partner email" do
      assert_equal @partner.email, @email.to.first
    end
    
    should "be sent from out account" do
      assert_equal "test@dnc.org", @email.from.first
    end
    
    should "have the subject 'Partner Account Confirmation'" do
      assert_equal "Partner Account Confirmation", @email.subject
    end
    
    should "contain the perishable token in the body" do
      assert_match @partner.perishable_token, @email.body
    end
  end

end
