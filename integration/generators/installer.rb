# frozen_string_literal: true

initializer "activetracker.rb" do
  File.read(ActiveTracker::Engine.root.join("integration", "templates", "initializer.rb"))
end

route "ActiveTracker::Router.load"
