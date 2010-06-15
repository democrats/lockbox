# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
env_file = File.expand_path(File.join(File.dirname(__FILE__),'..','config','environment'))
if File.exists?("#{env_file}.rb")
  require env_file
  require 'spec/autorun'
  require 'spec/rails'
  require 'authlogic/test_case'
else
  require 'rubygems'
  require 'mocha' # gem install jferris-mocha, not regular mocha
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

Spec::Runner.configure do |config|
  if defined?(Rails)
    config.use_transactional_fixtures = true
    config.use_instantiated_fixtures  = false
    config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
    config.include(Authlogic::TestCase)
  end
  config.mock_with Mocha::API
end
