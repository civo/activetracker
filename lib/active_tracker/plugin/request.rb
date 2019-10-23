module ActiveTracker
  module Plugin
    class Request < Base
      def self.register
        @logger = ActiveTracker::RailsLogger.new
        @logger.level = Rails.logger.level
        Rails.logger.extend(ActiveSupport::Logger.broadcast(@logger))

        ActiveSupport::Notifications.subscribe "start_processing.action_controller" do |event|
          current_tags_clear
          @logger.reset
          tag_current(id: SecureRandom.uuid)
          @output = ""
        end

        ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          request_processed(event)
        end

        Rails.application.middleware.insert_before Rack::Sendfile, ActiveTracker::OutputCapturer

        @@registered = true
      end

      def self.registered?
        @@registered rescue false
      end

      def self.resources_name
        :requests
      end

      def self.nav_svg
        svg = <<~EOF
          <svg width="16" height="16" viewBox="0 0 16 16" class="fill-current" xmlns="http://www.w3.org/2000/svg">
          <path d="M16 1.5V10.5C16 11.3281 15.3281 12 14.5 12H13V5.5C13 4.12187 11.8781 3 10.5 3H4V1.5C4 0.671875 4.67188 0 5.5 0H14.5C15.3281 0 16 0.671875 16 1.5ZM12 5.5V14.5C12 15.3281 11.3281 16 10.5 16H1.5C0.671875 16 0 15.3281 0 14.5V5.5C0 4.67188 0.671875 4 1.5 4H10.5C11.3281 4 12 4.67188 12 5.5ZM9.875 6.375C9.875 6.16875 9.70625 6 9.5 6H2.375C2.16875 6 2 6.16875 2 6.375V8H9.875V6.375Z" />
          </svg>
        EOF
        svg.html_safe
      end

      def self.nav_title
        "Requests"
      end

      def self.statistics
        ret = []
        @requests = ActiveTracker::Model.all("Request")
        @requests = @requests.select {|e| e.log_at >= 60.minutes.ago}

        num_requests = @requests.count

        percentage_error = 0
        if num_requests > 0
          num_errors = @requests.map {|r| r.tags[:status][0]}.select {|s| s=="4" || s=="5"}.count
          percentage_error = num_errors / @requests.count.to_f * 100.0
        end

        avg_milliseconds = @requests.map {|r| r.tags[:duration].to_i}.sum / num_requests

        ret << {plugin: self, label: "Requests/hour", value: num_requests}
        if percentage_error < 1.0
          ret << {plugin: self, label: "Error percentage", value: "%.1f%%" % percentage_error}
        else
          ret << {plugin: self, label: "Error percentage", value: "%.1f%%" % percentage_error, error: true}
        end
        ret << {plugin: self, label: "Avg time/request", value: "#{avg_milliseconds}ms"}

        ret
      end

      def self.filters=(value)
        @filters = value
      end

      def self.filters
        @filters ||= ["/#{ActiveTracker::Configuration.mountpoint}"]
      end

      def self.current_tags_clear
        @tags = {}
      end

      def self.tag_current(tags = {})
        @tags = current_tags.merge(tags)
      end

      def self.current_tags
        @tags || {}
      end

      def self.app_name
        ENV["APP_NAME"] || Rails.application.class.parent.to_s
      end

      def self.request_processed(event)
        tag_current status: event.payload[:status]
        tag_current duration: "#{@duration.to_i}ms"
        tag_current url: event.payload[:path]
        tag_current method: event.payload[:method]
        tag_current app: app_name
      end

      def self.output_capture(output)
        @output = output
      end

      def self.record_duration(duration)
        return if ActiveTracker::Plugin::Request.current_tags[:url] && filter_request?(ActiveTracker::Plugin::Request.current_tags[:url])

        @duration = duration
        log = @logger.lines[0, 65535] rescue ""

        _, status, duration = (@logger&.lines || "").force_encoding("UTF-8").match(/Completed (\d+) .*? in (\d+)ms/m).to_a
        tag_current status: status
        tag_current duration: "#{duration.to_i}ms"

        ActiveTracker::Model.save("Request", {log: log, output: @output},
          tags: ActiveTracker::Plugin::Request.current_tags,
          data_type: "full",
          expiry: 7.days,
          log_at: Time.now
        ) if ActiveTracker::Plugin::Request.current_tags.any? && ActiveTracker::Plugin::Request.current_tags[:id].present?
      end

      def self.filter_request?(path)
        ActiveTracker::Plugin::Request.filters.each do |filter|
          if filter.is_a?(Regexp)
            if filter.match(path)
              return true
            end
          else
            if path.start_with?(filter)
              return true
            end
          end
        end

        false
      end
    end
  end
end
