require 'digest'

module ActiveTracker
  module Plugin
    class Query < Base
      def self.register
        ActiveSupport::Notifications.subscribe "sql.active_record" do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          capture_query(event)
        end

        @@registered = true
      end

      def self.registered?
        @@registered rescue false
      end

      def self.resources_name
        :queries
      end

      def self.nav_svg
        svg = <<~EOF
        <svg aria-hidden="true" focusable="false" data-prefix="fas" data-icon="database" class="fill-current" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512" width="16" height="16"><path d="M448 73.143v45.714C448 159.143 347.667 192 224 192S0 159.143 0 118.857V73.143C0 32.857 100.333 0 224 0s224 32.857 224 73.143zM448 176v102.857C448 319.143 347.667 352 224 352S0 319.143 0 278.857V176c48.125 33.143 136.208 48.572 224 48.572S399.874 209.143 448 176zm0 160v102.857C448 479.143 347.667 512 224 512S0 479.143 0 438.857V336c48.125 33.143 136.208 48.572 224 48.572S399.874 369.143 448 336z"></path></svg>
        EOF
        svg.html_safe
      end

      def self.nav_title
        "Queries"
      end

      # TODO: This is crazy slow and needs a rewrite/reconsider
      # def self.statistics
      #   ret = []
        # queries = ActiveTracker::Model.all("Query")
        # queries = queries.select {|e| e.log_at >= 60.minutes.ago}

        # num_queries = 0
        # slow_queries = 0
        # total_duration = 0

        # queries.each do |query|
        #   actual_query = ActiveTracker::Model.find(query.key) rescue nil
        #   next unless actual_query
        #   slow_queries += actual_query.count if actual_query.last_duration > self.min_slow_duration_ms
        #   num_queries += actual_query.count
        #   total_duration += actual_query.last_duration * actual_query.count
        # end

        # ret << {plugin: self, label: "Queries/hour", value: num_queries}
        # if slow_queries == 0
        #   ret << {plugin: self, label: "Slow queries/hour", value: slow_queries}
        # else
        #   ret << {plugin: self, label: "Slow queries/hour", value: slow_queries, error: true}
        # end
        # ret << {plugin: self, label: "Avg time/query", value: "%.2fms" % (total_duration/num_queries)} if num_queries > 0

      #   ret
      # end

      def self.filters=(value)
        @filters = value
      end

      def self.filters
        @filters ||= ["SCHEMA", /^$/]
      end

      def self.min_slow_duration_ms=(value)
        @min_slow_duration_ms = value
      end

      def self.min_slow_duration_ms
        @min_slow_duration_ms ||= 100
      end

      def self.capture_query(event)
        tags = {
          sql: event.payload[:sql],
          name: event.payload[:name],
        }

        return if filter_query?(tags)

        ActiveTracker::Model.find_or_create("Query", tags:tags, data_type: "full") do |obj|
          if obj.persisted
            ActiveTracker::Model.delete(obj.key)
          end
          obj.data ||= {}
          obj.data["last_duration"] = event.duration
          obj.data["count"] = (obj.data["count"] || 0) + 1
          # Enough for most git commits to be referenced
          # so should be fine for SQL query hashes within an application
          obj.id = "Q" + Digest::SHA2.hexdigest(tags.inspect)[0,8]
          obj.expiry = 7.days
          obj.log_at = Time.now

          obj.data["at_requests"] ||= []
          if ActiveTracker::Plugin::Request.registered?
            begin
              id = ActiveTracker::Plugin::Request.current_tags[:id] rescue nil
              obj.data["at_requests"].prepend(id) if id.present?
              obj.data["at_requests"] = obj.data["at_requests"][0,20]
              ActiveTracker::Plugin::Request.current_tags[:at_queries] ||= []
              ActiveTracker::Plugin::Request.current_tags[:at_queries] << obj.id
            rescue Exception, ActiveRecord::StatementInvalid, NoMethodError
              # Sometimes during initial DB migration this will fail to insert
              # the current object
            end
          end
        end
      end

      def self.filter_query?(details)
        ActiveTracker::Plugin::Query.filters.each do |filter|
          if filter.is_a?(Regexp)
            if filter.match(details[:sql] || "") || filter.match(details[:name] || "")
              return true
            end
          else
            if (details[:sql] || "").include?(filter) || (details[:name] || "").include?(filter)
              return true
            end
          end
        end

        false
      end

    end
  end
end
