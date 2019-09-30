module ActiveTracker
  class Engine < ::Rails::Engine
    isolate_namespace ActiveTracker
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
  end
end
