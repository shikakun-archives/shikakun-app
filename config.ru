require 'rubygems'
require 'bundler'

Bundler.require

set :haml, :format => :html5

require './shikakun.rb'
run Sinatra::Application
