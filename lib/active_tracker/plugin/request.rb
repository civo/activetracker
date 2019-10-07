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
          event = ActiveSupport::Notifications::Event.new *args
          request_processed(event)
        end

        Rails.application.middleware.use ActiveTracker::OutputCapturer

        true
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
        @tags = @tags.merge(tags)
      end

      def self.current_tags
        @tags
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
        # Move these to the Civo apps
        # tags[:email] = request.headers["X-CivoCom-User-Email"] if request.headers["X-CivoCom-User-Email"].present?
        # tags[:civocom_request_path] = request.headers["X-CivoCom-Request-Path"] if request.headers["X-CivoCom-Request-Path"].present?
        # tags[:civocom_request_id] = request.headers["X-CivoCom-RequestID"] if request.headers["X-CivoCom-RequestID"].present?
      end

      def self.output_capture(output)
        @output = output
      end

      def self.record_duration(duration)
        return if filter_request?(ActiveTracker::Plugin::Request.current_tags[:url])

        @duration = duration

        ActiveTracker::Model.save("Request", {log: @logger.lines[0, 65535], output: @output},
          tags: ActiveTracker::Plugin::Request.current_tags,
          data_type: "full",
          expiry: 7.days,
          log_at: Time.current
        )
      end

      def self.filter_request?(path)
        Rails.logger.debug("ActiveTracker should filter #{path}?")
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

__END__




    ActiveTracker::Model.save("Job", {log: @log},
      tags: {job_name: @name, app: app_name, id: SecureRandom.uuid, duration: "#{(@end-@start).to_i}ms"},
      data_type: "output", expiry: 7.days, log_at: Time.current)

