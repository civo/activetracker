module ActiveTracker
  class RequestsController < ApplicationController
    def index
      ts = Time.current.to_f
      @requests = ActiveTracker::Model.all("Request")
      duration = (Time.current.to_f - ts) * 1000
      @requests, @pagination = ActiveTracker::Model.paginate(@requests, params[:page], ActiveTracker::Plugin::Request.per_page)
      @duration = duration
    end

    def show
      @request = ActiveTracker::Model.find(params[:id])
    end
  end
end
