# frozen_string_literal: true

initializer "activetracker.rb" do
  File.read(ActiveTracker::Engine.root.join("lib", "templates", "initializer.rb"))
end

route "ActiveTracker::Router.load"
