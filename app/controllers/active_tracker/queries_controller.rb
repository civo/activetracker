module ActiveTracker
  class QueriesController < ActiveTracker::BaseController
    def index
      ts = Time.current.to_f
      @queries = ActiveTracker::Model.all("Query")
      filter_queries if params[:q].present?
      duration = (Time.current.to_f - ts) * 1000
      @queries, @pagination = ActiveTracker::Model.paginate(@queries, params[:page], ActiveTracker::Configuration.per_page)
      @duration = duration
    end

    def show
      @query = ActiveTracker::Model.find(params[:id])
      @requests = @query.at_requests.map {|id| ActiveTracker::Model.find(id) rescue nil}.compact
    end

    private

    def filter_queries
      filters = params[:q].split(/\s+/)
      filtered = @queries.select do |query|
        acceptable = true
        filters.each do |filter|
          if filter[":"]
            key,value = filter.split(":")
            if query.tags[key.to_sym]&.downcase != value&.downcase
              acceptable = false
            end
          else
            acceptable = false unless query.tags[:sql][filter]
          end
        end
        acceptable
      end
      @queries = filtered
    end

  end
end
