module ActiveTracker
  class RequestsController < ApplicationController
    def index
      @requests = ActiveTracker::Model.all("Request")[0,20]
    end

    def show
      @request = ActiveTracker::Model.find(params[:id])
    end
  end
end
