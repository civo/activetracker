module ActiveTracker
  class QueriesController < ApplicationController
    def index
      ts = Time.current.to_f
      @queries = ActiveTracker::Model.all("Query")
      duration = (Time.current.to_f - ts) * 1000
      @queries, @pagination = ActiveTracker::Model.paginate(@queries, params[:page], ActiveTracker::Configuration.per_page)
      @duration = duration
    end

    def show
      @query = ActiveTracker::Model.find(params[:id])
      @requests = @query.at_requests.map {|id| ActiveTracker::Model.find(id) rescue nil}.compact
    end
  end
end
