# coding: utf-8

Sequel::Model.plugin(:schema)

db = {
  user:     ENV['USER'],
  dbname:   ENV['DBNAME'],
  password: ENV['PASSWORD'],
  host:     ENV['HOST']
}

configure :development do
  DB = Sequel.connect("sqlite://users.db")
end

configure :production do
  DB = Sequel.connect("mysql2://#{db[:user]}:#{db[:password]}@#{db[:host]}/#{db[:dbname]}")
end

class Users < Sequel::Model
  unless table_exists?
    DB.create_table :users do
      primary_key :id
      String :nickname
    end
  end
end

use Rack::Session::Cookie,
  :key => 'rack.session',
  :path => '/',
  :expire_after => 3600,
  :secret => ENV['SESSION_SECRET']

use OmniAuth::Builder do
  provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
end

Twitter.configure do |config|
  config.consumer_key       = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret    = ENV['TWITTER_CONSUMER_SECRET']
  config.oauth_token        = ENV['TWITTER_SHIKAKUN_TOKEN']
  config.oauth_token_secret = ENV['TWITTER_SHIKAKUN_TOKEN_SECRET']
end

not_found do
  "404鹿なし"
end

get "/pokes" do
  @users = Users.order_by(:nickname.asc)
  usary = []
  @users.each do |users|
    usary << users.nickname
  end
  @us = usary[rand(usary.length)]
  
  tweets = []
  max_id = 999999999999999999
  prev_max_id = 0
  
  (1 .. 20).each do |page|
    Twitter.user_timeline(@us, { max_id: max_id, count: 200 }).each do |tweet|
      tweets << tweet.text
      max_id = tweet.id
    end
    break if max_id == prev_max_id
    prev_max_id = max_id
    max_id -= 1
  end
  @tw = tweets[rand(tweets.length)]
  haml :index
end

get "/exit" do
  @users = Users.order_by(:nickname.asc)
  haml :exit
end

get "/auth/:provider/callback" do
  auth = request.env["omniauth.auth"]
  session["nickname"] = auth["info"]["nickname"]
  redirect '/join'
end

get '/join' do
  if session["nickname"].nil?
    redirect '/'
  elsif session["nickname"] == "shikakun"
    flash.next[:info] = "鹿 だ!!"
    redirect '/'
  else
    if Users.filter(nickname: session["nickname"]).empty?
      Users.find_or_create(:nickname => session["nickname"])
      shikatification = "鹿 さん、 #{session["nickname"]} さんがshikakunに参加しました"
      twitter_client = Twitter::Client.new
      twitter_client.update(shikatification) if settings.environment == :production
      flash.next[:info] = shikatification
      redirect '/'
    else
      flash.next[:info] = "鹿 さん、 #{session["nickname"]} さんがまたshikakunになりました"
      redirect '/'
    end
  end
end

get "/cancel" do
  if session["nickname"].nil?
    redirect '/'
  elsif session["nickname"] == "shikakun"
    redirect '/logout'
  else
    Users.filter(:nickname => session["nickname"]).delete
    shikatification = "鹿 さん、 #{session["nickname"]} さんがshikakunをやめました"
    twitter_client = Twitter::Client.new
    twitter_client.update(shikatification) if settings.environment == :production
    redirect '/logout'
  end
end

get "/logout" do
  session.clear
  redirect '/'
end
