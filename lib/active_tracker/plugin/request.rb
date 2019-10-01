module ActiveTracker
  module Plugin
    class Request < Base
      def self.register
        if defined?(Rails)
          Rails.application.middleware.delete Rails::Rack::Logger
          Rails.application.middleware.insert_before Rack::Sendfile, ActiveTracker::RailsLogger
        end
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

    end
  end
end
