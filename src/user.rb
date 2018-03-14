require 'json'
require 'twitter'

class User
  attr_accessor :line_id, :access_token, :access_secret

  # 最悪の実装，生まれたことを詫びろ
  # dbに格納したら逆引きが怪しいしどうするかな
  @@connected_users = []

  def initialize line_id,  access_token, access_secret
    @line_id = line_id
    @access_token = access_token
    @access_secret = access_secret
    @thread = nil

    @r_client = Twitter::REST::Client.new do |config|
      config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token = @access_token
      config.access_token_secret = @access_secret
    end

    @s_client = Twitter::Streaming::Client.new do |config|
      config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token = @access_token
      config.access_token_secret = @access_secret
    end
  end

  def self.create_from_hash hash
    User.new(hash['line_id'], hash['access_token'], hash['access_secret'])
  end

  def self.connected_users
    @@connected_users
  end

  def self.find_connected line_id
    @@connected_users.find {|u| u.line_id == line_id}
  end

  def tweet text
    @r_client.update text
  end

  def favorite tweet_id
    @r_client.favorite! tweet_id
  end

  def retweet tweet_id
    @r_client.retweet! tweet_id

  end

  def create_tweet_message tweet
    msg = $template.button_message
    msg['altText'] = tweet.text
    msg['template']['text'] = "<#{tweet.user.name}@#{tweet.user.screen_name}>\n #{tweet.text}"

    button_fav = $template.postback_action
    button_fav['label'] = 'favorite'
    button_fav['data'] = {
      type: 'favorite',
      tweet_id: tweet.id
    }.to_json
    msg['template']['actions'] << button_fav

    button_rt = $template.postback_action
    button_rt['label']= 'retweet'
    button_rt['data'] = {
      type: 'retweet',
      tweet_id: tweet.id
    }.to_json
    msg['template']['actions'] << button_rt
    
    msg
  end

  # reaction buttonつけろ
  def start_thread
    return false if @thread

    begin
    @thread = Thread.new do
      @s_client.user do |obj|
        case obj
        when Twitter::Tweet
          msg = create_tweet_message obj
          $client.push_message @line_id, msg
        when Twitter::DirectMessage
          # そのうち実装
        end
      end
    end
    rescue e
      puts e
    end

    return true
  end

  def stop_thread
    return false unless @thread

    @thread.kill
    @thread = nil
    return true
  end

end
