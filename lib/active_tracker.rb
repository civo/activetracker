require "active_tracker/version"
require "redis"

module ActiveTracker
  class Error < StandardError; end

  def self.reset_connection
    @redis = nil
  end

  def self.connection
    if @redis
      begin
        @redis.ping
      rescue
        @redis = nil
      end
    end

    @redis ||= Redis.new(url: ActiveTracker::Configuration.redis_url)

    begin
      @redis.ping
    rescue
      @redis = nil
    end

    @redis
  rescue Errno::ECONNREFUSED, Redis::CannotConnectError
    @redis = nil
  end

  def self.connection_offline?
    !connection
  end
end

require "active_tracker/configuration"
require "active_tracker/engine"
