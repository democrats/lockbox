ActionController::Routing::Routes.draw do |map|
  map.root :controller => "home", :action => "show"
  map.resources :partners
  
  map.resources :authentication, :only => [:show]
  
  map.resource :admin, :controller => "admin", :only => [:show] do |admin|
    admin.resources :partners, :controller => "admin/partners", :active_scaffold => true
  end
  
end
