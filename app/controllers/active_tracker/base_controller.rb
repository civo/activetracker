module ActiveTracker
  class BaseController < ActionController::Base
    protect_from_forgery with: :exception

    layout "active_tracker/active_tracker"

    before_action do
      if ActiveTracker::Configuration.authentication.is_a? String
        username, password = ActiveTracker::Configuration.authentication.split(":")
        unless authenticate_with_http_basic { |u, p| u == username && p == password}
          request_http_basic_authentication
        end
      elsif ActiveTracker::Configuration.authentication.is_a? Proc
        unless self.instance_eval &ActiveTracker::Configuration.authentication
          # Raise a 404, as we'd rather not let people know the URL is available
          # unless we have to for basic authentication
          raise ActionController::RoutingError.new('Not Found')
        end
      end
    end
  end
end
