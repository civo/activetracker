module ActiveTracker
  module Plugin
    class Base
      def self.nav_url
        ActiveTracker::Configuration.mountpoint + "/" + resources_name.to_s
      end
    end
  end
end
