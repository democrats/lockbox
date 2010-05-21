require 'spec_helper'

describe HomeController do

  context "Show" do
    subject do
      get :show
      response
    end
    
    it { should be_success }
    it { should render_template(:show) }
  end

end