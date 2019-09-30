module ActiveTracker
  class RequestsController < ApplicationController
    def index
      render plain: "Hello requests"
    end
  end
end
