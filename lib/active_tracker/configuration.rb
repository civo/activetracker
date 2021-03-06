module ActiveTracker
  class Configuration
    def self.plugins
      @@plugins ||= [
        ActiveTracker::Plugin::Request,
      ]
      @@plugins
    end

    def self.plugins=(items)
      items.each do |i|
        if i.respond_to?(:register)
          i.register
        else
          raise PluginInvalidError.new("#{i.name} doesn't correctly implement the ActiveTracker API")
        end
      end

      @@plugins = items.dup
    end

    def self.redis_url
      @@redis_url ||= "redis://localhost:6379/15"
    end

    def self.redis_url=(url)
      unless url.start_with?("redis://")
        raise PluginInvalidError.new("redis_url isn't a valid Redis URL - should begin with redis://")
      end
      @@redis_url = url
    end

    def self.mountpoint
      @@mountpoint ||= "activetracker"
    end

    def self.root_path
      "/#{mountpoint}"
    end

    def self.mountpoint=(path)
      @@mountpoint = path
    end

    def self.per_page=(value)
      @@per_page = value
    end

    def self.per_page
      @@per_page ||= 20
      @@per_page.to_i
    end

    def self.authentication(&block)
      if block
        @@authentication = block
      end
      @@authentication ||= nil
    end

    def self.authentication=(value)
      @@authentication = value
    end

    class PluginInvalidError < ActiveTracker::Error ; end
  end
end
