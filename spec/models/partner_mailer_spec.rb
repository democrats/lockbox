require 'spec_helper'

describe PartnerMailer do

  context "Confirmation Email" do
    let(:partner) { Factory.build(:partner) }
    
    subject do
      partner.stubs(:perishable_token).returns("1234")
      PartnerMailer.create_confirmation(partner)
    end
    
    it "should deliver to the partner email" do
      subject.to.first.should == partner.email
    end
    
    it "should be sent from out account" do
      subject.from.first.should == "test@dnc.org"
    end
    
    its(:subject) { should == "Partner Account Confirmation" }
    
    its(:body) { should =~ /#{partner.perishable_token}/ }
  end

  context "Fetch Password Email" do
    let(:partner) { Factory.build(:partner) }
    
    subject do
      partner.stubs(:perishable_token).returns("1234")
      PartnerMailer.create_fetch_password(partner)
    end

    it "should deliver to the partner email" do
      subject.to.first.should == partner.email
    end

    it "should be sent from out account" do
      subject.from.first.should == "test@dnc.org"
    end

    its(:subject) { should == "Fetch Password" }

    its(:body) { should =~ /#{partner.perishable_token}/ }
  end

end
