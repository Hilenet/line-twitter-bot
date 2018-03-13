require 'byebug'

require 'sinatra/base'
require 'sinatra/cookies'
require 'sinatra/reloader' 

require 'line/bot'

require_relative 'src/template'
require_relative 'src/authenticator'


class Server < Sinatra::Base
  set :port, 8080
  set :bind, "0.0.0.0"

  use Rack::Session::Cookie, {
    key: 'rack.session',
    expire_after: 60,
    secret: Digest::SHA256.hexdigest(rand.to_s)
  }


  helpers Sinatra::Cookies

  get '/' do
    "hoge"
  end

  # lineからuserが最初にアクセス
  # userが存在したら不要
  get '/register' do
    # validate is really from line
    # redisで存在確認
    session[:line_id] ||= params['line_id']
    request_token = $authenticator.get_request_token

    session[:twitter_request_token] = request_token

    redirect $authenticator.get_request_token.authorize_url
  end

  # twitterからリダイレクト
  # user作成，保存完了
  get '/auth' do
    error 400 do 'no request token' end unless session[:twitter_request_token]
    error 400 do 'no varifier' end unless params['oauth_verifier']
    
    request_token = session[:twitter_request_token]
    oauth_verifier = params['oauth_verifier']

    access_token = request_token.get_access_token(oauth_verifier: params['oauth_verifier'])


    redirect "line://oaMessage/@eaq0347r", 307
  end


  post '/line' do
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless $client.validate_signature(body, signature)
      puts "signature err"
      error 400 do 'Bad Request' end
    end

    events = $client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message

      when Line::Bot::Event::Follow
        # Redisの該当keyを確認        
        # 連携確認
        line_id = event['source']['userId']

        url = "https://line.hile.work/register?line_id=#{line_id}"
        msg = $template.text_message
        msg['text'] = "登録して，どうぞ\n#{url}"

        $client.push_message line_id, msg
        
      else
        error 400 do 'Bad Req Type' end
      end
    end
  end

  def get_follow(event)
    

  end
end


def setup()
  $client = Line::Bot::Client.new do |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_ACCESS_TOKEN"]
  end
  $template = Template.instance
  $authenticator = Authenticator.instance
end

setup()
Server.run!
