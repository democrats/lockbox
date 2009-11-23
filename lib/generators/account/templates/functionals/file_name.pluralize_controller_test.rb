require 'test_helper'

class <%= class_name %>sControllerTest < ActionController::TestCase

  context "Create" do
    setup do
      @<%= singular_name %> = Factory.build(:<%= singular_name %>)
      @<%= singular_name %>.stubs(:id).returns(1)
      <%= class_name %>Mailer.stubs(:deliver_confirmation)
    end
    
    context "Valid" do
      setup do
        @<%= singular_name %>.stubs(:save).returns(true)
        <%= class_name %>.stubs(:new).returns(@<%= singular_name %>)
        post :create, :<%= singular_name %> => Factory.attributes_for(:<%= singular_name %>)
      end
      
      should_redirect_to("root_path") { root_path }
      should "deliver the cofirmation mail" do
        assert_received(<%= class_name %>Mailer, :deliver_confirmation) { |expect| expect.with(@<%= singular_name %>) }
      end
    end
    
    context "Invalid" do
      setup do
        @<%= singular_name %>.stubs(:save).returns(false)
        <%= class_name %>.stubs(:new).returns(@<%= singular_name %>)
        post :create, :<%= singular_name %> => { }
      end
    
      should_render_template :new
      should "not deliver the confirmation mail" do
        assert_not_received(<%= class_name %>Mailer, :deliver_confirmation)
      end
    end
    
  end

  context "New" do
    setup do
      get :new
    end
    
    should_respond_with :success
    should_assign_to :<%= singular_name %>
  end
  
  context "Show" do
    setup do
      stubbed_session_for(:<%= singular_name %>)
      get :show
    end
    
    should_respond_with :success
    should_assign_to :<%= singular_name %>
  end
  
  context "Edit" do
    setup do
      stubbed_session_for(:<%= singular_name %>)
      get :edit
    end
    
    should_respond_with :success
    should_assign_to :<%= singular_name %>
  end
  
  context "Update" do
    setup do
      @<%= singular_name %> = Factory.build(:<%= singular_name %>)
    end
    
    context "Valid" do
      setup do
        @<%= singular_name %>.stubs(:save).returns(true)
        stubbed_session_for(@<%= singular_name %>)
        put :update, :<%= singular_name %> => { }
      end
      
      should_redirect_to("<%= singular_name %> path") { <%= singular_name %>_path(@<%= singular_name %>) }
    end
    
    context "Invalid" do
      setup do
        @<%= singular_name %>.stubs(:save).returns(false)
        stubbed_session_for(@<%= singular_name %>)
        put :update, :<%= singular_name %> => { }
      end
      
      should_render_template :edit
    end
  end
  
end
