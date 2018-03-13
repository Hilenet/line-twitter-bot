require 'oauth'
require 'oauth/consumer'

require 'singleton'


# OAuth周りの処理をwrap
class Authenticator
  include Singleton

  CALLBACK_URL = 'https://line.hile.work/auth'

  def initialize
    @consumer = OAuth::Consumer.new(
      ENV['TWITTER_CONSUMER_KEY'],
      ENV['TWITTER_CONSUMER_SECRET'],
      {
        site: 'https://twitter.com',
        authorize_path: '/oauth/authenticate'
      }
    )
  end

  def get_request_token
    @consumer.get_request_token({oauth_callback: CALLBACK_URL})
  end

end
