require 'test_helper'

class TestHelperTest < ActionView::TestCase

  context "Flash Helper" do
    should "cycle through the flash hash and generate formatted messages" do
      debugger
      flash[:success] = "Success!"
      flash[:error]   = "Error!"
      assert_match /<div class="\flash-success\">Success!<\/div>/, helper.flash_helper
      assert_match /<div class="\flash-error\">Error!<\/div>/, helper.flash_helper
    end
  end

end
