begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = 'lockbox_middleware'
    gemspec.summary = 'Rack middleware for the LockBox centralized API authorization service.'
    gemspec.description = 'Rack middleware for the LockBox centralized API authorization service. Brought to you by the DNC Innovation Lab.'
    gemspec.email = 'innovationlab@dnc.org'
    gemspec.homepage = 'http://github.com/dnclabs/lockbox'
    gemspec.authors = ['Chris Gill', 'Nathan Woodhull', 'Brian Cardarella', 'Wes Morgan']
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end