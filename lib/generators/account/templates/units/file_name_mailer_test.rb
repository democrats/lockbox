require 'test_helper'

class <%= class_name %>MailerTest < ActionMailer::TestCase

  context "Confirmation Email" do
    setup do
      @<%= singular_name %> = Factory.build(:<%= singular_name %>)
      @<%= singular_name %>.stubs(:perishable_token).returns.returns("1234")
      @email = <%= class_name %>Mailer.create_confirmation(@<%= singular_name %>)
    end
    
    should "deliver to the <%= singular_name %> email" do
      assert_equal @<%= singular_name %>.email, @email.to.first
    end
    
    should "be sent from out account" do
      assert_equal "confirmation@dnc.org", @email.from.first
    end
    
    should "have the subject '<%= class_name %> Account Confirmation'" do
      assert_equal "<%= class_name %> Account Confirmation", @email.subject
    end
    
    should "contain the perishable token in the body" do
      assert_match @<%= singular_name %>.perishable_token, @email.body
    end
  end

  context "Fetch Password Email" do
    setup do
      @<%= singular_name %> = Factory.build(:<%= singular_name %>)
      @<%= singular_name %>.stubs(:perishable_token).returns.returns("1234")
      @email = <%= class_name %>Mailer.create_fetch_password(@<%= singular_name %>)
    end
    
    should "deliver to the <%= singular_name %> email" do
      assert_equal @<%= singular_name %>.email, @email.to.first
    end
    
    should "be sent from out account" do
      assert_equal "fetch_password@dnc.org", @email.from.first
    end
    
    should "have the subject 'Fetch Password'" do
      assert_equal "Fetch Password", @email.subject
    end
    
    should "contain the perishable token in the body" do
      assert_match @<%= singular_name %>.perishable_token, @email.body
    end
  end

end
