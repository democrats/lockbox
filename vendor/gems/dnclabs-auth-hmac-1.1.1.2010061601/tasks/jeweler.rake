require 'auth-hmac/version'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "dnclabs-auth-hmac"
    gemspec.summary = "A gem providing HMAC based authentication for HTTP"
    gemspec.description = "A gem providing HMAC based authentication for HTTP. This version includes DNC Innovation Lab changes (improvements?). See History.txt for details."
    gemspec.email = "innovationlab@dnc.org"
    gemspec.homepage = "http://github.com/dnclabs/auth-hmac"
    gemspec.authors = ['Sean Geoghegan', 'ascarter', 'Wes Morgan']
    gemspec.version = AuthHMAC::VERSION::STRING
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end