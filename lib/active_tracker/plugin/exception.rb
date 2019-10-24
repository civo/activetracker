module ActiveTracker
  module Plugin
    class Exception < Base
      def self.register
        Rails.application.middleware.insert_after BetterErrors::Middleware, ActiveTracker::ExceptionCapturer

        @@registered = true
      end

      def self.registered?
        @@registered rescue false
      end

      def self.resources_name
        :exceptions
      end

      def self.statistics
        ret = []
        @exceptions = ActiveTracker::Model.all("Exception")
        num_exceptions = @exceptions.count
        exceptions_last_day = @exceptions.select {|e| e.log_at >= 1.day.ago}.count
        exceptions_last_30_minutes = @exceptions.select {|e| e.log_at >= 30.minutes.ago}.count

        ret << {plugin: self, label: "Last 24 hours", value: exceptions_last_day}
        if exceptions_last_30_minutes == 0
          ret << {plugin: self, label: "Last 30 min", value: exceptions_last_30_minutes}
        else
          ret << {plugin: self, label: "Last 30 min", value: exceptions_last_30_minutes, error: true}
        end

        ret
      end

      def self.nav_svg
        svg = <<~EOF
          <svg width="16" height="16" viewBox="0 0 16 16" class="fill-current" xmlns="http://www.w3.org/2000/svg">
          <path d="M13.7656 2.76562L12.1406 4.39062L12.9688 5.21875C13.2625 5.5125 13.2625 5.9875 12.9688 6.27812L12.425 6.82188C12.7937 7.6375 13 8.54375 13 9.49687C13 13.0875 10.0906 15.9969 6.5 15.9969C2.90937 15.9969 0 13.0906 0 9.5C0 5.90938 2.90937 3 6.5 3C7.45312 3 8.35938 3.20625 9.175 3.575L9.71875 3.03125C10.0125 2.7375 10.4875 2.7375 10.7781 3.03125L11.6062 3.85938L13.2312 2.23438L13.7656 2.76562ZM15.625 1.875H14.875C14.6687 1.875 14.5 2.04375 14.5 2.25C14.5 2.45625 14.6687 2.625 14.875 2.625H15.625C15.8313 2.625 16 2.45625 16 2.25C16 2.04375 15.8313 1.875 15.625 1.875ZM13.75 0C13.5437 0 13.375 0.16875 13.375 0.375V1.125C13.375 1.33125 13.5437 1.5 13.75 1.5C13.9563 1.5 14.125 1.33125 14.125 1.125V0.375C14.125 0.16875 13.9563 0 13.75 0ZM14.8094 1.71875L15.3406 1.1875C15.4875 1.04062 15.4875 0.803125 15.3406 0.65625C15.1937 0.509375 14.9563 0.509375 14.8094 0.65625L14.2781 1.1875C14.1312 1.33438 14.1312 1.57187 14.2781 1.71875C14.4281 1.86563 14.6656 1.86563 14.8094 1.71875ZM12.6906 1.71875C12.8375 1.86563 13.075 1.86563 13.2219 1.71875C13.3688 1.57187 13.3688 1.33438 13.2219 1.1875L12.6906 0.65625C12.5437 0.509375 12.3063 0.509375 12.1594 0.65625C12.0125 0.803125 12.0125 1.04062 12.1594 1.1875L12.6906 1.71875ZM14.8094 2.78125C14.6625 2.63438 14.425 2.63438 14.2781 2.78125C14.1312 2.92812 14.1312 3.16563 14.2781 3.3125L14.8094 3.84375C14.9563 3.99062 15.1937 3.99062 15.3406 3.84375C15.4875 3.69688 15.4875 3.45937 15.3406 3.3125L14.8094 2.78125ZM3.5 8.5C3.5 7.39687 4.39687 6.5 5.5 6.5C5.775 6.5 6 6.275 6 6C6 5.725 5.775 5.5 5.5 5.5C3.84687 5.5 2.5 6.84688 2.5 8.5C2.5 8.775 2.725 9 3 9C3.275 9 3.5 8.775 3.5 8.5Z"/>
          </svg>
        EOF
        svg.html_safe
      end

      def self.nav_title
        "Exceptions"
      end

      def self.filters=(value)
        @filters = value
      end

      def self.filters
        @filters ||= []
      end

      def self.exception_capture(class_name, message, backtrace)
        return if filter_exception?(class_name)

        tags = {
          class_name: class_name,
          backtrace_hash: Digest::SHA2.hexdigest(backtrace.first.to_s),
        }

        ActiveTracker::Model.find_or_create("Exception", tags:tags, data_type: "full") do |obj|
          if obj.persisted
            ActiveTracker::Model.delete(obj.key)
          end
          obj.data ||= {}
          obj.data["count"] = (obj.data["count"] || 0) + 1
          # Enough for most git commits to be referenced
          # so should be fine for exception hashes within an application
          obj.id = "E" + Digest::SHA2.hexdigest(tags.inspect)[0,8]
          obj.expiry = 7.days
          obj.log_at = Time.now

          obj.data["backtrace"] = backtrace
          obj.data["message"] = message

          obj.data["at_requests"] ||= []
          if ActiveTracker::Plugin::Request.registered?
            id = ActiveTracker::Plugin::Request.current_tags[:id] rescue nil
            obj.data["at_requests"].prepend(id) if id.present?
            obj.data["at_requests"] = obj.data["at_requests"][0,20]
            ActiveTracker::Plugin::Request.current_tags[:at_exceptions] ||= []
            ActiveTracker::Plugin::Request.current_tags[:at_exceptions] << obj.id
          end
        end
      end

      def self.filter_exception?(class_name)
        ActiveTracker::Plugin::Exception.filters.each do |filter|
          if filter.is_a?(Regexp)
            if filter.match(class_name)
              return true
            end
          elsif filter.is_a?(String)
            if class_name == filter
              return true
            end
          elsif filter.is_a?(Exception)
            if class_name == filter.class.name
              return true
            end
          end
        end

        false
      end


    end
  end
end
