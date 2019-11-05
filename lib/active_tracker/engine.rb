module ActiveTracker
  class Engine < ::Rails::Engine
    isolate_namespace ActiveTracker
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
    config.autoload_paths += Dir["#{config.root}/app/**/"]

    initializer 'active_tracker_helper.action_controller' do
      ActiveSupport.on_load :action_controller do
        helper ActiveTracker::ImagesHelper
        helper ActiveTracker::ApplicationHelper
        helper ActiveTracker::PaginationHelper
        helper ActiveTracker::OutputHelper
      end
    end

    config.generators do |g|
      g.test_framework :rspec, fixture: false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      g.assets false
      g.helper false
    end

    if defined?(Sprockets)
      config.assets.precompile += %w(active_tracker_manifest active_tracker/active_tracker.js active_tracker/active_tracker.css)
    end
  end
end
