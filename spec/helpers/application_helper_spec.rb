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
end
