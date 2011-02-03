source "http://rubygems.org"

gem "rails", "2.3.8"
gem "rack", "1.1.0"
gem "dnclabs-auth-hmac", :require => "auth-hmac"
gem "httpotato"
gem "net-ssh"
gem "pg"
gem "paperclip"
gem "authlogic"

group :test, :cucumber do
  gem "rack-test"
  gem "rspec", "~> 1.3.1"
  gem "rspec-rails"
  gem "factory_girl"
  gem "shoulda"
  gem "jferris-mocha", :require => false
end

group :test, :development, :cucumber do
  gem "ruby-debug"
end

group :development do
  gem "geminabox"
end
