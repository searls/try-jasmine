require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'httparty'

get '/' do
	File.read(File.join('public', 'index.html'))
end

get '/gists/:gist_id' do
  HTTParty.get("https://api.github.com/gists/#{params[:gist_id]}").body
end