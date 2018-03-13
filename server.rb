require 'byebug'

require 'sinatra/base'
require 'sinatra/cookies'
require 'sinatra/reloader' 

require 'line/bot'

require_relative 'src/authenticator'
require_relative 'src/redis_util'
require_relative 'src/template'


class Server < Sinatra::Base
  set :port, 8080
  set :bind, "0.0.0.0"

  use Rack::Session::Cookie, {
    key: 'rack.session',
    expire_after: 60,
    secret: Digest::SHA256.hexdigest(rand.to_s)
  }


  get '/' do
    "hoge"
  end

  # lineからuserが最初にアクセス
  # userが存在したら不要
  get '/register' do

    # redisで存在確認
    session[:line_id] ||= params['line_id']
    redirect "line://oaMessage/@eaq0347r", 307 if $redis.get_user params[:line_id]

    # request_token取ってきて，twitterにリダイレクト
    request_token = $authenticator.get_request_token
    session[:twitter_request_token] = request_token

    redirect request_token.authorize_url
  end

  # twitterからリダイレクト
  # user作成，保存完了
  get '/auth' do
    error 400 do 'no line id' end unless session[:line_id]
    error 400 do 'no request token' end unless session[:twitter_request_token]
    error 400 do 'no varifier' end unless params['oauth_verifier']
    
    request_token = session[:twitter_request_token]
    oauth_verifier = params['oauth_verifier']

    access_token = request_token.get_access_token(oauth_verifier: oauth_verifier)
    $redis.set_hash({
      line_id: session[:line_id],
      access_token: access_token.token,
      access_secret: access_token.secret
    })
    byebug

    redirect "line://oaMessage/@eaq0347r", 307
  end


  # webhook
  post '/line' do
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless $client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    events = $client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        # 未連携ユーザなら勧告
        line_id = event['source']['userId']
        user = $redis.get_user line_id
        unless user
          msg = $template.text_message
          msg['text'] = "Twitter連携が行われていません．"

          $client.push_message line_id, msg
          
          error 400 do 'yet authenticated twitter' end
        end

        text = event['message']['text']
        case text
        when "start"
          connected_user = User.find_connected line_id
          if connected_user
            puts "already connected"
          else
            user.start_thread
            User.connected_users << user
            
            msg = $template.text_message
            msg['text'] = "<system> stream配信を開始"
            $client.push_message line_id, msg
          end
        when "stop"
          connected_user = User.find_connected line_id
          unless connected_user
            puts "yet connected"
          else
            connected_user.stop_thread
            User.connected_users.delete connected_user

            msg = $template.text_message
            msg['text'] = '<system> stream配信を終了'
            $client.push_message line_id, msg
          end
        end

      when Line::Bot::Event::Follow
        res = get_follow(event)

        error 400 do 'Bad Req Type' end unless res
      end
    end
  end

  def get_follow(event)
    line_id = event['source']['userId']

    # 登録済なら弾く
    user = $redis.get_user(line_id)
    return false unless user

    url = "https://line.hile.work/register?line_id=#{line_id}"
    msg = $template.text_message
    msg['text'] = "登録して，どうぞ\n#{url}"

    $client.push_message line_id, msg
    return true
  end
end


def setup()
  $client = Line::Bot::Client.new do |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_ACCESS_TOKEN"]
  end
  $template = Template.instance
  $authenticator = Authenticator.instance
  $redis = RedisUtil.instance
end

setup()
Server.run!
