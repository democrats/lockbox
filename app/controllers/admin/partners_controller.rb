class Admin::PartnersController < AdminController

  active_scaffold :partner do |config|
    config.label = "API Partners"
    update.columns.exclude [:password, :password_confirmation]
    list.columns = [:id, :email, :name, :organization, :phone_number, :api_key, :max_requests]
    create.columns = [:email, :name, :organization, :phone_number, :max_requests, :password, :password_confirmation]
    list.sorting = {:id => 'DESC'}
    update.columns.exclude :api_key
    search.columns = [:email, :name, :organization, :api_key]
    columns[:max_requests].label = "Requests per Hour"
  end

end
