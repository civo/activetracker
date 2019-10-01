module ActiveTracker
  class Engine < ::Rails::Engine
    isolate_namespace ActiveTracker
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    initializer 'active_tracker_helper.action_controller' do
      ActiveSupport.on_load :action_controller do
        helper ActiveTracker::ImagesHelper
      end
    end

  end
end
