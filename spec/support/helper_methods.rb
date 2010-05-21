module HelperMethods
  def session_for(partner)
     @partner = partner
     if @partner.is_a?(Symbol) || @partner.is_a?(String)
       @partner = Factory(partner)
     end
     PartnerSession.create(@partner)
   end
 
   def stubbed_session_for(partner)
     @partner = partner
     if @partner.is_a?(Symbol) || @partner.is_a?(String)
       @partner = Factory(partner)
     end
     @controller.stubs(:current_user).returns(@partner)
   end

   def current_user
     @partner ||= session_for(:partner)
   end
 
   def assert_not_received(mock, expected_method_name)
     matcher = have_received(expected_method_name)
     yield(matcher) if block_given?
     assert !matcher.matches?(mock), matcher.failure_message
   end

   def admin_login
     @request.env['HTTP_AUTHORIZATION'] = 'Basic ' + Base64::encode64("admin:10ckb0X")
   end
end