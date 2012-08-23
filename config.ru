require 'rubygems'
require 'bundler'

Bundler.require

set :haml, :format => :html5

get '/stylesheet.css' do
  scss :stylesheet
end

envfile = File.expand_path(File.join(Dir.pwd, ".env"))

if File.exists?(envfile)
  File.open(envfile, "r").each do |line|
    key, val = line.split("=", 2)
    ENV[key] = val
  end
end

require './shikakun.rb'
run Sinatra::Application
