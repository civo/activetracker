module ActiveTracker
  class RequestsController < ApplicationController
    def index
      ts = Time.current.to_f
      @requests = ActiveTracker::Model.all("Request")
      duration = (Time.current.to_f - ts) * 1000
      @requests, @pagination = ActiveTracker::Model.paginate(@requests, params[:page], ActiveTracker::Configuration.per_page)
      @duration = duration
    end

    def show
      @request = ActiveTracker::Model.find(params[:id])
      query_ids = JSON.parse(@request.tags[:at_queries]) rescue []
      @queries = query_ids.map {|id| ActiveTracker::Model.find(id) rescue nil}.compact
    end
  end
end
