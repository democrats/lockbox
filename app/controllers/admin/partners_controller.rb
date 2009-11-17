class Admin::PartnersController < AdminController

  active_scaffold :partner do |config|
    config.label = "API Partners"
    config.actions.exclude :create
    update.columns.exclude [:password, :password_confirmation]
    list.columns = [:id, :email, :name, :organization, :phone_number, :api_key, :max_requests]
    list.sorting = {:id => 'DESC'}
    update.columns.exclude :api_key
    search.columns = [:email, :name, :organization]
    columns[:max_requests].label = "Requests per Hour"
  end

end
