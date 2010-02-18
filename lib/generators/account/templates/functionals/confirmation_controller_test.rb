require 'test_helper'

class ConfirmationControllerTest < ActionController::TestCase

  context "Update" do
    setup do
      @perishable_token = "1234"
      @<%= singular_name %> = Factory.build(:<%= singular_name %>, :confirmed => false)
      @<%= singular_name %>.stubs(:save).returns(true)
      <%= class_name %>.stubs(:find_by_perishable_token!).returns(@<%= singular_name %>)
      <%= class_name %>Session.stubs(:create)
      get :update, :perishable_token => @perishable_token
    end
    
    should_redirect_to("root_path") { root_path }
    should "confirm the <%= singular_name %>" do
      assert @<%= singular_name %>.confirmed?
      assert_received(@<%= singular_name %>, :save)
    end
    should "find by the perishable token" do
      assert_received(<%= class_name %>, :find_by_perishable_token!) { |expect| expect.with(@perishable_token) }
    end
    should "log the <%= singular_name %> in" do
      assert_received(<%= class_name %>Session, :create) { |expect| expect.with(@<%= singular_name %>) }
    end
  end
end
