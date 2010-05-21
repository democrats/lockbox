# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "lockbox_middleware"
    gemspec.files = ['lib/lockbox_middleware.rb', 'lib/lockbox_cache.rb']
    gemspec.add_dependency('httparty', '>= 0.5.2')
    gemspec.summary = "Centralized API authorization"
    gemspec.description = "Rack middleware for the Lockbox centralized API authorization service. Brought to you by the DNC Innovation Lab."
    gemspec.email = "innovationlab@dnc.org"
    # gemspec.homepage = "http://foo.org/gems/lockbox"
    gemspec.authors = ["Chris Gill", "Brian Cardarella", "Nathan Woodhull", "Wes Morgan"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

task :default => :spec