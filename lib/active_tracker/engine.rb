module ActiveTracker
  class Engine < ::Rails::Engine
    isolate_namespace ActiveTracker
    config.eager_load_paths += Dir["#{config.root}/lib/**/"]
    config.eager_load_paths += Dir["#{config.root}/app/**/"]

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
