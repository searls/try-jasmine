require 'rubygems'
require 'bundler/setup'
require 'sinatra'

require 'rack/coffee'

use Rack::Coffee, {
    :root => 'public',
    :urls => ['/spec']
}

get '/' do
  redirect '/index.html'
end

