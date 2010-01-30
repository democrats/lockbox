require 'test_helper'

class <%= class_name %>SessionsControllerTest < ActionController::TestCase

  context "Show" do
    setup do
      get :new
    end
    
    should_respond_with(:success)
  end
  
  context "Create" do
    setup do
      @<%= singular_name %> = Factory(:<%= singular_name %>)
    end

    context "Valid" do
      setup do
        post :create, :<%= singular_name %>_session => { :email => @<%= singular_name %>.email, 
                                         :password => @<%= singular_name %>.password }
      end
      should_redirect_to("root_path") { root_path }
      should_set_the_flash_to "You have been signed in"
    end
    
    context "Does not exist" do
      setup do
        post :create, :<%= singular_name %>_session => { :email => "x_#{@<%= singular_name %>.email}",
                                         :password => @<%= singular_name %>.password }
      end
      should_render_template :new
      should_set_the_flash_to "Email doesn't exist or bad Pasword"
    end

    context "Bad Password" do
      setup do
        post :create, :<%= singular_name %>_session => { :email => @<%= singular_name %>.email, 
                                         :password => "x_#{@<%= singular_name %>.password}" }
      end
      should_render_template :new
      should_set_the_flash_to "Email doesn't exist or bad Pasword"
    end

  end
  
  context "Destroy" do
    setup do
      activate_authlogic
      @<%= singular_name %> = Factory(:<%= singular_name %>)
      @current_<%= singular_name %>_session = mock("<%= singular_name %>_session")
      @current_<%= singular_name %>_session.stubs(:record => @<%= singular_name %>)
      @current_<%= singular_name %>_session.stubs(:destroy => true)
      <%= class_name %>Session.stubs(:find => @current_<%= singular_name %>_session)
      session_for(@<%= singular_name %>)
      
      delete :destroy
    end
    
    should_set_the_flash_to "You have been logged out"
    should_redirect_to("root_path") { root_path }
    should "destory the session" do
      assert_received(@current_<%= singular_name %>_session, :destroy)
    end
  end

end