require 'test_helper'

class PartnerTest < ActiveSupport::TestCase
  context "a partner object" do
    setup { @partner = Partner.new }
    subject { @partner }
    should_validate_presence_of :name, :organization, :phone_number, :email

    should "reject bad emails" do
      bads = ["bad bad", "bad_email_something"]
      goods = ["good@google.com", "good+email@potato.com"]
      bads.each do |email|
        @partner.email = email
        @partner.save
        assert @partner.errors.on(:email)
      end
      goods.each do |email|
        @partner.email = email
        @partner.save
        assert !@partner.errors.on(:email)
      end
    end

    context "phone Number" do
      context "Normalization" do
        should "remove all non numerics from the phone number" do
          @partner.phone_number = "123-456-7890"
          assert_equal "1234567890", @partner.attributes["phone_number"]
          @partner.phone_number = "123.456.7890"
          assert_equal "1234567890", @partner.attributes["phone_number"]
          @partner.phone_number = "(123) 456-7890"
          assert_equal "1234567890", @partner.attributes["phone_number"]
        end

        should "reformat the phone_number into (xxx) xxx-xxxx" do
          @partner.phone_number = 1234567890
          assert_equal "(123) 456-7890", @partner.phone_number
        end
      end
    end

    context "api key" do
      should "create api key before validations" do
        @partner.valid?
        assert @partner.api_key.present?
      end
    end
  end
end
