module ActiveTracker
  class DashboardController < ActiveTracker::BaseController
    def index
      @statistics = []
      ActiveTracker::Configuration.plugins.each do |plugin|
        @statistics << [*plugin.statistics] if plugin.respond_to?(:statistics)
      end
    end
  end
end
