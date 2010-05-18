require 'test_helper'

class HomeControllerTest < ActionController::TestCase

  context "Show" do
    setup do
      get :show
    end
    
    should_respond_with(:success)
    should_render_template(:show)
  end

end
