require 'rubygems'
require 'sinatra'
require 'lockbox_middleware'

use Rack::Lint
use LockBox

get '/test' do
  "SUCCESSFUL GET"
end

post '/test' do
  "SUCCESSFUL POST"
end
