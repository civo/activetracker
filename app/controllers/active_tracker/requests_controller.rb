module ActiveTracker
  class RequestsController < ActiveTracker::BaseController
    def index
      ts = Time.current.to_f
      @requests = ActiveTracker::Model.all("Request")
      filter_requests if params[:q].present?
      duration = (Time.current.to_f - ts) * 1000
      @requests, @pagination = ActiveTracker::Model.paginate(@requests, params[:page], ActiveTracker::Configuration.per_page)
      @duration = duration
    end

    def show
      @request = ActiveTracker::Model.find(params[:id])
      query_ids = JSON.parse(@request.tags[:at_queries]) rescue []
      @queries = query_ids.map {|id| ActiveTracker::Model.find(id) rescue nil}.compact
      exception_ids = JSON.parse(@request.tags[:at_exceptions]) rescue []
      @exceptions = exception_ids.map {|id| ActiveTracker::Model.find(id) rescue nil}.compact
    end

    private

    def filter_requests
      filters = params[:q].split(/\s+/)
      filtered = @requests.select do |request|
        acceptable = true
        filters.each do |filter|
          if filter[":"]
            key,value = filter.split(":")
            if request.tags[key.to_sym]&.downcase != value&.downcase
              acceptable = false
            end
          else
            acceptable = false unless request.tags[:url][filter]
          end
        end
        acceptable
      end
      @requests = filtered
    end
  end
end
