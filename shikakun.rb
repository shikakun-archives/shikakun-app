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
      String :uid
      String :nickname
      String :image
      String :token
      String :secret
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

def tweet(shikatification)
  if settings.environment == :production
    twitter_client = Twitter::Client.new
    twitter_client.update(shikatification)
  elsif settings.environment == :development
    flash.next[:info] = shikatification
  end
end

get "/" do
  @users = Users.order_by(:nickname.asc)
  slim :index
end

get "/auth/:provider/callback" do
  auth = request.env["omniauth.auth"]
  session['uid'] = auth['uid']
  session['nickname'] = auth['info']['nickname']
  session['image'] = auth['info']['image']
  session['token'] = auth['credentials']['token']
  session['secret'] = auth['credentials']['secret']
  redirect '/join'
end

get '/join' do
  if session["nickname"].nil?
    redirect '/'
  elsif session["nickname"] == "shikakun"
    flash.next[:info] = "鹿だ !!"
    redirect '/'
  else
    if Users.filter(nickname: session["nickname"]).empty?
      Users.find_or_create(
        :uid => session['uid'],
        :nickname => session['nickname'],
        :image => session['image'],
        :token => session['token'],
        :secret => session['secret']
      )
      tweet("鹿 さん、 #{session['nickname']} さんがshikakunに参加しました")
      flash.next[:info] = "鹿 さん、 #{session['nickname']} さんがshikakunに参加しました"
      redirect '/'
    else
      flash.next[:info] = "鹿 さん、 #{session['nickname']} さんがまたshikakunになりました"
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
    tweet("鹿 さん、 #{session['nickname']} さんがshikakunをやめました")
    redirect '/logout'
  end
end

get "/logout" do
  session.clear
  redirect '/'
end
