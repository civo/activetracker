module ActiveTracker
  class Router
    def self.load
      Rails.application.routes.draw do
        namespace ActiveTracker::Configuration.mountpoint, as: "active_tracker", module: "active_tracker" do
          root 'dashboard#index'

          ActiveTracker::Configuration.plugins.each do |plugin|
            resources plugin.resources_name
          end
        end
      end
      Rails.application.routes.instance_variable_set(:@url_helpers, nil)
    end

    def self.reload
      load
      Rails.application.routes_reloader.reload!
      Rails.application.reload_routes!
    end
  end
end
