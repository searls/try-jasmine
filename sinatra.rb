require 'rubygems'
require 'bundler/setup'
require 'sinatra'

get '/' do
  redirect '/index.html'
end