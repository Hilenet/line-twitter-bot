require 'json'
require 'redis'
require 'singleton'
require_relative 'user'


class RedisUtil
  include Singleton

  attr_accessor :redis

  def initialize
    @redis = Redis.new(host: 'line_redis', db: 'users')
  end


  # hashからredisにuser格納
  def set_hash hash
    # symbolと文字列に対応 (これなんとかならんのか)
    line_id = hash[:line_id] || hash['line_id']
    access_token = hash[:access_token] || hash['access_token']
    access_secret = hash[:access_secret] || hash['access_secret']
    return false unless line_id && access_token && access_secret

    json = {line_id: line_id, access_token: access_token, access_secret: access_secret}.to_json

    @redis.set(line_id, json)
    puts "set user #{line_id}"
    return true
  end


  # redisからjson拾ってUser作って返す
  # user / nil
  def get_user line_id
    json_record = @redis.get line_id
    return nil unless json_record

    hash = JSON.parse json_record

    User.create_from_hash hash
  end

end
