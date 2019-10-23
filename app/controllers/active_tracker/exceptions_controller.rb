module ActiveTracker
  class ExceptionsController < ActiveTracker::BaseController
    def index
      ts = Time.current.to_f
      @exceptions = ActiveTracker::Model.all("Exception")
      filter_exceptions if params[:q].present?
      duration = (Time.current.to_f - ts) * 1000
      @exceptions, @pagination = ActiveTracker::Model.paginate(@exceptions, params[:page], ActiveTracker::Configuration.per_page)
      @duration = duration
    end

    def show
      @exception = ActiveTracker::Model.find(params[:id])
      @requests = @exception.at_requests.map {|id| ActiveTracker::Model.find(id) rescue nil}.compact
    end

    private

    def filter_exceptions
      filters = params[:q].split(/\s+/)
      filtered = @exceptions.select do |exception|
        acceptable = true
        filters.each do |filter|
          if filter[":"]
            key,value = filter.split(":")
            if exception.tags[key.to_sym]&.downcase != value&.downcase
              acceptable = false
            end
          else
            unless (exception.tags[:class_name] || "").downcase[filter.downcase] || (exception.message || "").downcase[filter.downcase]
              acceptable = false
            end
          end
        end
        acceptable
      end
      @exceptions = filtered
    end

  end
end
