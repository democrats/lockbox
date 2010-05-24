ActionController::Routing::Routes.draw do |map|
  
  # Authentication
  map.login "/login", :controller => 'partner_sessions', :action => "new"
  map.logout "/logout", :controller => 'partner_sessions', :action => "destroy"
  map.resources :partner_sessions, :only => :create
  map.resources :fetch_password, :only => [:index, :show]
  map.resource :fetch_password, :controller => "fetch_password", 
    :only => [:update, :create], :name_prefix => "singular_"

  map.signup "/signup", :controller => "partners", :action => "new"
  map.resources :partners
  
  map.connect "/confirm/:perishable_token", :controller => "confirmation",
    :action => "update"
  map.resources :authentication, :only => [:show]
  
  map.resource :admin, :controller => "admin", :only => [:show] do |admin|
    admin.resources :partners, :controller => "admin/partners", :active_scaffold => true
  end

  map.root :controller => "home", :action => "show"
  map.connect "/test_exception_notification/:id", :controller => 'application', :action => 'test_exception_notification'
end
