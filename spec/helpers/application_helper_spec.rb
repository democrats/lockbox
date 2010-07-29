require 'spec_helper'

describe ApplicationHelper do
  describe "#flash_helper" do
    it "should wrap flash messages in a div with the correct CSS class" do
      {:notice => 'foo', :error => 'bar'}.each_pair do |key, message|
        flash[key] = message
        helper.flash_helper.should match /<div class="flash-#{key.to_s}">#{message}<\/div>/
      end
    end
  end

  context "Table Helper" do
    before(:each){ 3.times { Factory(:partner)} }

    it "should create a table from a collection" do
      helper.table_helper(Partner.all, [:name,
                              {:name_2 => Proc.new{|e| e.name }}]).should == ""
    end
  end
end
