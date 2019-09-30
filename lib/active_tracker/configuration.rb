module ActiveTracker
  class Configuration
    cattr_accessor :redis_url

    def self.plugins
      @plugins ||= [
        ActiveTracker::Plugin::Request,
        # ActiveTracker::Plugin::Schedule,
        # ActiveTracker::Plugin::Exception,
        # ActiveTracker::Plugin::ActiveJob,
        # ActiveTracker::Plugin::ActionMail,
        # ActiveTracker::Plugin::Event,
        # ActiveTracker::Plugin::ActiveRecord,
      ]
      @plugins
    end

    def self.plugins=(items)
      items.each do |i|
        if i.respond_to?(:register)
          i.register
        else
          raise PluginInvalidError.new("#{i.name} doesn't correctly implement the ActiveTracker API")
        end
      end

      @plugins = items.dup
    end

    def self.redis_url
      @redis_url ||= "redis://localhost:6379/15"
    end

    def self.redis_url=(url)
      # TODO validate it begins with redis://
      @redis_url = url
    end

    def self.mountpoint
      @mountpoint ||= "activetracker"
    end

    def self.mountpoint=(path)
      @mountpoint = path
    end

    class PluginInvalidError < ActiveTracker::Error ; end
  end
end
