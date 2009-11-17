require 'test_helper'

class PartnersControllerTest < ActionController::TestCase
  context "creating a partner" do
    setup { post :create, :partner => Factory.attributes_for(:partner)}
    should_respond_with :redirect

    should "create a partner" do
      Partner.count == 1
    end   
  end

  context "trying to create an invalid partner" do
    setup { post :create, :partner => {:name => 'george washington',
                                       :organization => "foo",
                                       :email => 'woodhull@gmail.com'
                                       }}
    should_respond_with :success
    should_render_template :new
    should_assign_to :partner

    should "not create a partner" do
      Partner.count == 0
    end
  end

  context "new partner" do
    setup { get :new}
    should_respond_with :success
    should_render_template 'new'
    should_assign_to :partner
  end

  context "with a partner" do
    setup do
      session_for(:partner)
    end

    context "show" do
      setup {get :show, :id => @partner.id}
      should_respond_with :success
      should_render_template 'show'
      should_assign_to :partner
    end
  end
  
end
