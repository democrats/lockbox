require 'spec_helper'

describe Partner do
  context "a saved partner object" do
    subject { Factory(:partner) }
    
    context "uniqueness of api key" do
      it { should validate_uniqueness_of :api_key }
    end
    
    context "uniqueness of slug" do
      it { should validate_uniqueness_of :slug }
    end
    
    it "should not authenticate for invalid api key" do
      Partner.authenticate("randomapikey").authorized.should be_false
    end
    
    it "should not authenticate for blank api key" do
      Partner.authenticate('').authorized.should be_false
      Partner.authenticate(nil).authorized.should be_false
    end

    it "should authenticate if request count is below max requests" do
      Partner.authenticate(subject.api_key).authorized.should be_true
    end

    it "should increment api current request count" do
      count = subject.current_request_count
      Partner.authenticate(subject.api_key)
      subject.current_request_count.should == count+1 
    end

    it "should not authenticate if request count has exceeded max requests" do
      subject.requests_remaining.times do
        subject.increment_request_count
      end
      subject.requests_remaining.should == 0
      Partner.authenticate(subject.api_key).authorized.should be_false
    end
    
    it "should maintain remaining requests properly" do
      subject.requests_remaining.should == 100
      subject.increment_request_count
      subject.requests_remaining.should == 99
      subject.current_request_count.should == 1
      subject.increment_request_count
      subject.requests_remaining.should == 98
      subject.current_request_count.should == 2
    end
    
    context "rate limit reset time" do

      it "should return the next hour as the reset time" do
        this_hour = Time.parse(Time.now.strftime("%Y-%m-%d %H:00:00"))
        next_hour_epoch = 1.hour.since(this_hour).to_i
        subject.max_requests_reset_time.should == next_hour_epoch
      end

      it "should reset at the reset time" do
        before_reset = 1.second.until(Time.at(subject.max_requests_reset_time))
        after_reset = Time.at(subject.max_requests_reset_time)
        Time.stubs(:now).returns(before_reset)
        subject.requests_remaining.times do
          subject.increment_request_count
        end
        subject.requests_remaining.should == 0
        Partner.authenticate(subject.api_key).authorized.should be_false
        Time.stubs(:now).returns(after_reset)
        subject.requests_remaining.should == subject.max_requests
        Partner.authenticate(subject.api_key).authorized.should be_true
      end
    end

    context "with a protected application" do
      before(:each) do
        @pa = Factory(:protected_application)
        subject.protected_applications.push(@pa)
        subject.save!
      end

      it "should have a protected application" do
        subject.protected_applications.count.should == 1
        subject.protected_applications.first.should == @pa
      end

      it "should be authorized for the application" do
        subject.authorized_for_application?(@pa.name).should == true
      end

      it "should be authorized" do
          subject.authorized(@pa.name).should == true
      end
    end

    context "without a protected application" do
      before(:each) do
        @pa = Factory(:protected_application)
      end

      it "should not have a protected application" do
        subject.protected_applications.count.should == 0
      end

      it "should not be authorized for the application" do
        subject.authorized_for_application?(@pa.name).should == false
      end

      it "should not be authorized" do
        subject.authorized(@pa.name).should == false
      end
    end
  end

  context "an unsaved partner object" do
    subject { Factory.build(:partner) }
    
    it { should validate_presence_of :name }
    it { should validate_presence_of :organization }
    it { should validate_presence_of :phone_number }
    it { should validate_presence_of :email }

    it "should reject bad emails" do
      bads = ["bad bad", "bad_email_something"]
      goods = ["good@google.com", "good+email@potato.com"]
      bads.each do |email|
        subject.email = email
        subject.save
        subject.errors.on(:email).should_not be_empty
      end
      goods.each do |email|
        subject.email = email
        subject.save
        subject.errors.on(:email).should be_nil
      end
    end

    context "phone Number" do
      context "Normalization" do
        it "should remove all non numerics from the phone number" do
          subject.phone_number = "123-456-7890"
          subject.attributes["phone_number"].should == "1234567890"
          subject.phone_number = "123.456.7890"
          subject.attributes["phone_number"].should == "1234567890"
          subject.phone_number = "(123) 456-7890"
          subject.attributes["phone_number"].should == "1234567890"
        end

        it "should reformat the phone_number into (xxx) xxx-xxxx" do
          subject.phone_number = 1234567890
          subject.phone_number.should == "(123) 456-7890"
        end
      end
    end

    context "slug" do
      it "should only generate on create" do
        subject.slug.should be_nil
        subject.save
        subject.slug.should_not be_nil
      end
      
      it "should not change when the object is modified" do
        subject.save
        lambda {
          subject.name = "Foo"
          subject.save.should be_true
        }.should_not change(subject, :slug)
      end
      
      it "should be the parameterized name" do
        subject.name = 'Name Foo'
        subject.organization = nil
        subject.send(:make_slug).should == "name-foo"
      end

      context "with an organization" do
        it "should be the parameterized org name" do
          subject.organization = 'My Big Org'
          subject.name = nil
          subject.send(:make_slug).should == 'my-big-org'
        end
      end
      
      context "with a name & organization" do
        it "should be the parameterized org name and partner's name" do
          subject.organization = 'My Big Org'
          subject.name = 'My Name'
          subject.send(:make_slug).should == 'my-big-org-my-name'
        end
      end
    end
    
    context "API Key" do
      it "should generate an API key on create only" do
        subject.api_key.should be_nil
        subject.save
        subject.api_key.should_not be_nil
      end
      
      it "should not change when the object is modified" do
        subject.save
        lambda {
          subject.name ="Foo"
          subject.save.should be_true
        }.should_not change(subject, :api_key)
      end
    end
  end
end
