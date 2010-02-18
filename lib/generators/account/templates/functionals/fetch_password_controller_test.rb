require 'test_helper'

class FetchPasswordControllerTest < ActionController::TestCase

  context "Index" do
    setup do
      @<%= singular_name %> = <%= class_name %>.new
      <%= class_name %>.stubs(:new).returns(@<%= singular_name %>)
      get :index
    end
    
    should_respond_with(:success)
    should "create a new instance of <%= class_name %>" do
      assert_received(<%= class_name %>, :new)
    end
  end
  
  context "Show" do
    setup do
      @<%= singular_name %>          = Factory.build(:<%= singular_name %>)
      @<%= singular_name %>_session  = <%= class_name %>Session.new
      @perishable_token = "1234"
      <%= class_name %>.stubs(:find_by_perishable_token!).returns(@<%= singular_name %>)
    end
    
    context "Authenticates" do
      setup do
        @<%= singular_name %>_session.stubs(:save).returns(true)
        <%= class_name %>Session.stubs(:new).returns(@<%= singular_name %>_session)
        get :show, :id => @perishable_token
      end
      
      should_respond_with(:success)
    end
    
    context "Does not authenticate" do
      setup do
        @<%= singular_name %>_session.stubs(:save).returns(false)
        <%= class_name %>Session.stubs(:new).returns(@<%= singular_name %>_session)
        get :show, :id => @perishable_token
      end
      
      should_redirect_to("fetch_password_index_path") { fetch_password_index_path }
    end
  end
  
  context "Create" do
    context "Valid" do
      setup do
        @<%= singular_name %> = Factory.build(:<%= singular_name %>)
        <%= class_name %>.stubs(:find_by_email).returns(@<%= singular_name %>)
        <%= class_name %>Mailer.stubs(:deliver_fetch_password)
        post :create, :<%= singular_name %> => { :email => @<%= singular_name %>.email }
      end
      
      should_redirect_to("root_path") { root_path }
      should "find a <%= singular_name %> by the email" do
        assert_received(<%= class_name %>, :find_by_email) { |expect| expect.with(@<%= singular_name %>.email) }
      end
      should "deliver an email to the <%= singular_name %>" do
        assert_received(<%= class_name %>Mailer, :deliver_fetch_password) { |expect| expect.with(@<%= singular_name %>) }
      end
    end
  
    context "Invalid" do
      setup do
        @<%= singular_name %> = <%= class_name %>.new(:email => "bademail@test.com")
        <%= class_name %>.stubs(:find_by_email).returns(nil)
        <%= class_name %>Mailer.stubs(:deliver_fetch_password)
        post :create, :<%= singular_name %> => { :email => @<%= singular_name %>.email }
      end
      
      should_render_template(:index)
      should "assign a new instance of <%= class_name %> to @<%= singular_name %>" do
        assert assigns(:<%= singular_name %>).new_record?
      end
      should "try to find a <%= singular_name %> by the email" do
        assert_received(<%= class_name %>, :find_by_email) { |expect| expect.with(@<%= singular_name %>.email) }
      end
      should "not deliver an email" do
        assert_not_received(<%= class_name %>Mailer, :deliver_fetch_password)
      end
    end
  end

  context "Update" do
    setup do
      stubbed_session_for(:<%= singular_name %>)
    end
    
    context "Valid" do
      setup do
        @<%= singular_name %>.stubs(:save).returns(true)
        @password = "goodpassword"
        FetchPasswordController.any_instance.stubs(:current_<%= singular_name %>).returns(@<%= singular_name %>)
        put :update, :<%= singular_name %> => { :password => @password, :password_confirmation => @password }
      end
      
      should_redirect_to("root_path") { root_path }
      should "attempt to save the record " do
        assert_received(@<%= singular_name %>, :save)
      end
    end
    
    context "Invalid" do
      setup do
        @<%= singular_name %>.stubs(:save).returns(false)
        @password = "badpassword"
        FetchPasswordController.any_instance.stubs(:current_<%= singular_name %>).returns(@<%= singular_name %>)
        put :update, :<%= singular_name %> => { :password => @password }
      end
      
      should_render_template(:show)
      should "attempt to save the record " do
        assert_received(@<%= singular_name %>, :save)
      end
    end
  end

end