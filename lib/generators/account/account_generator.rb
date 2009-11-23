require 'ruby-debug'

class AccountGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      # Libs
      m.directory "lib"
      m.template "libs/authentication.rb", "lib/authentication.rb"
      
      # Models
      m.directory "app/models"
      m.template "models/file_name.rb", "app/models/#{file_name}.rb"
      m.template "models/file_name_session.rb", "app/models/#{file_name}_session.rb"
      m.template "models/file_name_mailer.rb", "app/models/#{file_name}_mailer.rb"
      
      # Migrations
      m.directory "db/migrate"
      m.migration_template "migrations/model_migration.rb", "db/migrate",
        :assigns => { :migration_name => "Create#{class_name.pluralize}" },
        :migration_file_name => "create_#{file_path.pluralize}"
      
      # Controllers
      m.directory "app/controllers"
      m.template "controllers/file_name.pluralize_controller.rb", "app/controllers/#{file_name.pluralize}_controller.rb"
      m.template "controllers/file_name_sessions_controller.rb", "app/controllers/#{file_name}_sessions_controller.rb"
      m.template "controllers/confirmation_controller.rb", "app/controllers/confirmation_controller.rb"
      m.template "controllers/fetch_password_controller.rb", "app/controllers/fetch_password_controller.rb"
      
      # Views
      m.directory "app/views"
      m.directory "app/views/#{file_name.pluralize}"
      m.template "views/file_name.pluralize/_form.html.erb", "app/views/#{file_name.pluralize}/_form.html.erb"
      m.template "views/file_name.pluralize/edit.html.erb", "app/views/#{file_name.pluralize}/edit.html.erb"
      m.template "views/file_name.pluralize/index.html.erb", "app/views/#{file_name.pluralize}/index.html.erb"
      m.template "views/file_name.pluralize/new.html.erb", "app/views/#{file_name.pluralize}/new.html.erb"
      m.template "views/file_name.pluralize/show.html.erb", "app/views/#{file_name.pluralize}/show.html.erb"
      m.directory "app/views/#{file_name}_sessions"
      m.template "views/file_name_sessions/new.html.erb", "app/views/#{file_name}_sessions/new.html.erb"
      m.directory "app/views/fetch_password"
      m.template "views/fetch_password/index.html.erb", "app/views/fetch_password/index.html.erb"
      m.template "views/fetch_password/show.html.erb", "app/views/fetch_password/show.html.erb"
      m.directory "app/views/#{file_name}_mailer"
      m.template "views/file_name_mailer/confirmation.html.erb", "app/views/#{file_name}_mailer/confirmation.html.erb"
      m.template "views/file_name_mailer/fetch_password.html.erb", "app/views/#{file_name}_mailer/fetch_password.html.erb"
      m.directory "app/views/shared"
      m.template "views/shared/_logged_in_menu.html.erb", "app/views/shared/_logged_in_menu.html.erb"
      m.template "views/shared/_logged_out_menu.html.erb", "app/views/shared/_logged_out_menu.html.erb"
      
      # Helpers
      m.directory "app/helpers"
      m.template "helpers/session_helper.rb", "app/helpers/session_helper.rb"
      
      # Tests
        m.directory "test"
        # Unit
        m.directory "test/unit"
        m.template "units/file_name_test.rb", "test/unit/#{file_name}_test.rb"
        m.template "units/file_name_session_test.rb", "test/unit/#{file_name}_session_test.rb"
        m.template "units/file_name_mailer_test.rb", "test/unit/#{file_name}_mailer.rb"
        
        # Functional
        m.directory "test/functional"
        m.template "functionals/file_name.pluralize_controller_test.rb", "test/functional/#{file_name.pluralize}_controller_test.rb"
        m.template "functionals/file_name_sessions_controller_test.rb", "test/functional/#{file_name}_sessions_controller_test.rb"
        m.template "functionals/confirmation_controller_test.rb", "test/functional/confirmation_controller_test.rb"
        m.template "functionals/fetch_password_controller_test.rb", "test/functional/fetch_password_controller_test.rb"
        
        # Factories
        m.directory "test/factories"
        m.template "factories/file_name_factory.rb", "test/factories/#{file_name}_factory.rb"
      
      # Code Injection
      m.add_routes
      m.add_authentication
      m.add_test_helpers
      m.add_skip_before_filter
      m.add_partials_to_layout
      m.add_css
    end
  end
  
end

module AccountGeneratorCommands
  
  def add_routes
    sentinel = 'ActionController::Routing::Routes.draw do |map|'
    logger.route 'Adding Account Routes'
    routes = <<-ROUTES
    
  # Authentication
  map.connect '/login', :controller => '#{singular_name}_sessions', :action => 'new'
  map.connect '/logout', :controller => '#{singular_name}_sessions', :action => 'destroy'
  map.resources :#{singular_name}_sessions, :only => :create
  map.resources :fetch_password, :only => [:index, :show]
  map.resource :fetch_password, :controller => 'fetch_password', 
    :only => [:update, :create], :name_prefix => 'singular_'
    
  # Account Creation
  map.connect '/signup', :controller => '#{plural_name}', :action => 'new'
  map.resources :#{plural_name}, :only => [:create, :index, :new]
  map.connect '/confirm/:perishable_token', :controller => 'confirmation',
    :action => 'update'
    
  # Account Management
  map.resource :#{singular_name}, :controller => "#{plural_name}", :only => [:show, :edit, :update]
    ROUTES
    
    gsub_file 'config/routes.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
      "#{match}\n#{routes}"
    end
  end

  def add_authentication
    logger.create 'Adding Authentication'
    sentinel = 'class ApplicationController < ActionController::Base'
    gsub_file 'app/controllers/application_controller.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
      "#{match}\n  include Authentication\n"
    end

    sentinel = 'Rails::Initializer.run do |config|'    
    gsub_file 'config/environment.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
      "#{match}\n  config.gem 'authlogic'\n"
    end
  end
  
  def add_test_helpers
    sentinel_class    = 'class ActiveSupport::TestCase'
    sentinel_required = 'require \'test_help\''
    required_file     = 'require \'authlogic/test_case\''
    
    logger.create 'Adding Test Helpers'
    helpers = <<-HELPERS
  def session_for(#{singular_name})
    @#{singular_name} = #{singular_name}
    if @#{singular_name}.is_a?(Symbol) || @#{singular_name}.is_a?(String)
      @#{singular_name} = Factory(#{singular_name})
    end
    #{class_name}Session.create(@#{singular_name})
  end

  def stubbed_session_for(#{singular_name})
    @#{singular_name} = #{singular_name}
    if @#{singular_name}.is_a?(Symbol) || @#{singular_name}.is_a?(String)
      @#{singular_name} = Factory.build(#{singular_name})
    end
    @controller.stubs(:current_user).returns(@#{singular_name})
  end

  def current_user
    @#{singular_name} ||= session_for(:#{singular_name})
  end

  def assert_not_received(mock, expected_method_name)
    matcher = have_received(expected_method_name)
    yield(matcher) if block_given?
    assert !matcher.matches?(mock), matcher.failure_message
  end
    HELPERS
    
    activate_authlogic = <<-ACTIVATE_AUTHLOGIC
class ActionController::TestCase
  setup :activate_authlogic
end
    ACTIVATE_AUTHLOGIC
    
    gsub_file 'test/test_helper.rb', /(#{Regexp.escape(sentinel_class)})/mi do |match|
      "#{match}\n#{helpers}"
    end
    gsub_file 'test/test_helper.rb', /(#{Regexp.escape(sentinel_required)})/mi do |match|
      "#{match}\n#{required_file}"
    end
    File.open('test/test_helper.rb', 'a+') { |f| f.write("\n#{activate_authlogic}")}
  end
  
  def add_skip_before_filter
    controllers = [
      ['app/controllers/home_controller.rb', 'class HomeController < ApplicationController']
    ]
    logger.create 'Adding skip_before_filter :require_user to HomeController'
    before_filter = 'skip_before_filter :require_user'
    
    controllers.each do |file, sentinel|
      gsub_file file, /#{Regexp.escape(sentinel)}/mi do |match|
        "#{match}\n  #{before_filter}"
      end
    end
  end
  
  def add_partials_to_layout
    logger.create 'Adding partials to layout'
    sentinel = '<div id="main" class="span-24 last">'
    session_header = <<-SESSION_HEADER
        <div id="session_header">
          <%= session_header %>
        </div>
    SESSION_HEADER
    gsub_file 'app/views/layouts/application.html.erb', /(#{Regexp.escape(sentinel)})/mi do |match|
      "#{match}\n#{session_header}\n"
    end
  end
  
  def add_css
    logger.create 'Adding CSS'
    css = <<-CSS
#session_header {
  float: right;
}
    CSS
    File.open('public/stylesheets/application.css', 'a+') { |f| f.write("\n#{css}")}
  end

end

Rails::Generator::Commands::Create.send(:include, AccountGeneratorCommands)