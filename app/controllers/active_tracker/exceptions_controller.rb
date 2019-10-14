module ActiveTracker
  class ExceptionsController < ApplicationController
    def index
      ts = Time.current.to_f
      @exceptions = ActiveTracker::Model.all("Exception")
      duration = (Time.current.to_f - ts) * 1000
      @exceptions, @pagination = ActiveTracker::Model.paginate(@exceptions, params[:page], ActiveTracker::Configuration.per_page)
      @duration = duration
    end

    def show
      @exception = ActiveTracker::Model.find(params[:id])
      @requests = @exception.at_requests.map {|id| ActiveTracker::Model.find(id) rescue nil}.compact
    end
  end
end
