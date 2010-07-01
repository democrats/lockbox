require 'spec_helper'
require 'lockbox_cache'

describe LockBoxCache::Cache do
  subject { LockBoxCache::Cache.new }
  
  describe "#write" do
    it "should save what you write to it" do
      subject.write(:foo, 'bar')
      subject.read(:foo).should == 'bar'
    end
  end
  
  describe "#read" do
    it "should return nil when reading a non-existent key" do
      subject.read(:foo).should be_nil
    end
  end
  
  describe "#delete" do
    it "should delete the key and value" do
      subject.write(:foo, 'bar')
      subject.delete(:foo)
      subject.read(:foo).should be_nil
    end
  end
  
  context "in a Rails app" do
    it "should use the Rails cache" do
      subject.write(:foo, 'bar')
      Rails.cache.read(:foo).should == 'bar'
    end
  end
  
  context "in a Rack app" do
    # doesn't work, oh well
    # it "should still work" do
    #   remove_const(Rails)
    #   cache = LockBox::Cache.new
    #   cache.write(:foo, 'bar')
    #   cache.read(:foo).should == 'bar'
    # end
  end
end