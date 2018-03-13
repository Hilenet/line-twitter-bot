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

    @client = Twitter::Streaming::Client.new do |config|
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


  # TODO: threadに入れていい感じに呼ぶべし 
  def start_thread
    return false if @thread

    @thread = Thread.new do
      @client.user do |obj|
        case obj
        when Twitter::Tweet
          msg = $template.text_message
          msg['text'] = obj.text
          $client.push_message line_id, msg
        when Twitter::DirectMessage
          # そのうち実装
        end
      end
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
