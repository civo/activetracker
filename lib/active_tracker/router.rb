module ActiveTracker
  class Router
    def self.load
      Rails.application.routes.draw do
        namespace ActiveTracker::Configuration.mountpoint, module: "active_tracker" do
          root 'dashboard#index'

          ActiveTracker::Configuration.plugins.each do |plugin|
            resources plugin.resources_name
          end
        end
      end
    end

    def self.reload
      Rails.application.routes_reloader.reload!
    end
  end
end
