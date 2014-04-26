require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'httparty'

get '/' do
	File.read(File.join('public', 'index.html'))
end

get '/gists/:gist_id' do
  resp = HTTParty.get "https://api.github.com/gists/#{params[:gist_id]}",
                      :headers => { 'User-Agent' => 'Try-Jasmine' }
  resp.body
end
