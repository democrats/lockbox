require 'test_helper'

class PartnerTest < ActiveSupport::TestCase
  context "a saved partner object" do

    setup do
       @partner = Factory(:partner)
       #don't overwrite the key that they think will be duplicated
       Partner.any_instance.stubs(:create_api_key).returns(true)
     end
     
    subject { @partner }
    
    should_validate_uniqueness_of :api_key
    

    

    
    should "not authenticate for invalid api key" do
      assert_equal(false, Partner.authenticate("randomapikey"))
    end
    
    should "not authenticate for blank api key" do
      assert_equal(false, Partner.authenticate(''))
      assert_equal(false, Partner.authenticate(nil))
    end

    should "authenticate if request count is below max requests" do
      assert_equal(true, Partner.authenticate(@partner.api_key))
    end

    should "increment api current request count" do
      count = @partner.current_request_count
      Partner.authenticate(@partner.api_key)
      assert_equal(count + 1, @partner.current_request_count)
    end

    should "not authenticate if request count has exceeded max requests" do
      @partner.requests_remaining.times do
        @partner.increment_request_count
      end
      assert_equal(0, @partner.requests_remaining)
      assert_equal(false, Partner.authenticate(@partner.api_key))
    end
    
    should "maintain remaining requests properly" do
      assert_equal(100, @partner.requests_remaining)
      @partner.increment_request_count
      assert_equal(99, @partner.requests_remaining)
      assert_equal(1, @partner.current_request_count)
      @partner.increment_request_count
      assert_equal(98, @partner.requests_remaining)
      assert_equal(2, @partner.current_request_count)
    end

  end


  context "an unsaved partner object" do
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
