require "active_support/core_ext/time/conversions"
require "active_support/core_ext/object/blank"
require "action_dispatch/http/request"
require "rack/body_proxy"

module ActiveTracker
  class RailsLogger
    def initialize
      reset
    end

    def reset
      @lines = ""
    end

    def lines
      @lines
    end

    def add(severity, message = nil, progname = nil)
      severity ||= UNKNOWN
      return true if severity < level

      if message.nil?
        if block_given?
          message = yield
        else
          message = progname
        end
      end

      @lines << "#{message}\n"
      true
    end
    alias log add

    def debug?; @level <= DEBUG; end
    def debug!; self.level = DEBUG; end
    def info?; @level <= INFO; end
    def info!; self.level = INFO; end
    def warn?; @level <= WARN; end
    def warn!; self.level = WARN; end
    def error?; @level <= ERROR; end
    def error!; self.level = ERROR; end
    def fatal?; @level <= FATAL; end
    def fatal!; self.level = FATAL; end

    def debug(message)
      message = yield if block_given?
      return if message.blank?
      add(DEBUG, message)
    end

    def info(message = "")
      message = yield if block_given?
      return if message.blank?
      add(INFO, message)

      # matches = message.match(/Completed (\d+) .*? in (\d+)ms/)
      # if matches
      #   @status = matches[1]
      #   @time_taken = matches[2]
      # end
      # @lines << message if info? && @recording
    end

    def warn(message = "")
      message = yield if block_given?
      return if message.blank?
      add(WARN, message)
    end

    def error(message = "")
      message = yield if block_given?
      return if message.blank?
      add(ERROR, message)
    end

    def fatal(message = "")
      message = yield if block_given?
      return if message.blank?
      add(FATAL, message)
    end

    def level
      @level
    end

    def level=(severity)
      if severity.is_a?(Integer)
        @level = severity
      else
        case severity.to_s.downcase
        when 'debug'
          @level = DEBUG
        when 'info'
          @level = INFO
        when 'warn'
          @level = WARN
        when 'error'
          @level = ERROR
        when 'fatal'
          @level = FATAL
        when 'unknown'
          @level = UNKNOWN
        else
          raise ArgumentError, "invalid log level: #{severity}"
        end
      end
    end

    def formatter
      ActiveSupport::Logger::SimpleFormatter
    end

    def silence(*args)
      yield self
    end
  end
end
