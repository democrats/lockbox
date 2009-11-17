ActionController::Routing::Routes.draw do |map|
  
  # Authentication
  map.connect "/login", :controller => 'partner_sessions', :action => "new"
  map.connect "/logout", :controller => 'partner_sessions', :action => "destroy"
  map.resources :partner_sessions, :only => :create
  # map.resources :fetch_password, :only => [:index, :show]
  # map.resource :fetch_password, :controller => "fetch_password", 
  #   :only => [:update, :create], :name_prefix => "singular_"


  map.resources :partners, :only => [:create, :show, :index, :new]
  
  map.resources :authentication, :only => [:show]
  
  map.resource :admin, :controller => "admin", :only => [:show] do |admin|
    admin.resources :partners, :controller => "admin/partners", :active_scaffold => true
  end

  map.root :controller => "home", :action => "show"  
end
