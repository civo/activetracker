require "active_support/core_ext/time/conversions"
require "active_support/core_ext/object/blank"
require "active_support/log_subscriber"
require "action_dispatch/http/request"
require "rack/body_proxy"

module ActiveTracker
  class RailsLogger < ActiveSupport::LogSubscriber
    def initialize(app, taggers = nil)
      @app         = app
      @taggers     = taggers || []
      Rails.logger = ActionView::Base.logger = ActionController::Base.logger = ActiveRecord::Base.logger = self
      $stdout.sync = true
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      call_app(request, env)
    end

    def app_name
      ENV["APP_NAME"] || Rails.application.class.parent.to_s
    end

    def debug(message = "")
      message = yield if block_given?
      return if message.blank?
      @lines << message if debug? && @recording
    end

    def debug?
      %i{debug}.include?(level)
    end

    def info(message = "")
      message = yield if block_given?
      return if message.blank?

      matches = message.match(/Completed (\d+) .*? in (\d+)ms/)
      if matches
        @status = matches[1]
        @time_taken = matches[2]
      end
      @lines << message if info? && @recording
    end

    def info?
      %i{debug info}.include?(level)
    end

    def warn(message = "")
      message = yield if block_given?
      return if message.blank?
      @lines << message if warn? && @recording
    end

    def warn?
      %i{debug info warn}.include?(level)
    end

    def error(message = "")
      message = yield if block_given?
      return if message.blank?
      @lines << message if error? && @recording
    end

    def error?
      %i{debug info warn error}.include?(level)
    end

    def fatal(message = "")
      message = yield if block_given?
      return if message.blank?
      @lines << message if fatal? && @recording
    end

    def fatal?
      %i{debug info warn error fatal}.include?(level)
    end

    def level
      Rails.configuration.log_level
    end

    def formatter
      ActiveSupport::Logger::SimpleFormatter
    end

    def start_worker(name)
      @name = name
      @lines = []
      @start = Time.now.to_f * 1000
      @recording = true
    end

    def end_worker
      @log = @lines.join("\n")

      puts @log

      @end = Time.now.to_f * 1000

      # data = {
      #   values:    { log: @log, log_size: @log.length, ms_taken: (@end-@start).to_i },
      #   tags:      { job_name: @name, app: app_name, run_id: SecureRandom.uuid },
      #   timestamp: (Time.now.to_f * 1000.0).to_i
      # }

      ActiveTracker::Model.save("Job", {log: @log},
        tags: {job_name: @name, app: app_name, id: SecureRandom.uuid, duration: "#{(@end-@start).to_i}ms"},
        data_type: "output", expiry: 7.days, log_at: Time.current)

    ensure
      @recording = false
    end

    def silence(*args)
      yield self
    end

    private

    def call_app(request, env)
      Rails.logger = ActionView::Base.logger = ActionController::Base.logger = ActiveRecord::Base.logger = self
      instrumenter = ActiveSupport::Notifications.instrumenter
      instrumenter.start "request.action_dispatch", request: request
      logger.info { started_request_message(request) }

      @lines = []
      @recording = true
      @status = nil
      @time_taken = nil
      @url = request.fullpath
      ActiveTracker::Plugin::Request.current_tags_clear
      status, headers, response = @app.call(env)
      @status = status.to_s
      finish(request, response)
      [status, headers, response]
    rescue Exception => e
      finish(request, [e.message])
      raise
    ensure
      ActiveSupport::LogSubscriber.flush_all!
    end

    # Started GET "/session/new" for 127.0.0.1 at 2012-09-26 14:51:42 -0700
    def started_request_message(request) # :doc:
      'Started %s "%s" for %s at %s' % [
        request.request_method,
        request.filtered_path,
        request.ip,
        Time.now.to_default_s ]
    end

    def compute_tags(request) # :doc:
      @taggers.collect do |tag|
        case tag
        when Proc
          tag.call(request)
        when Symbol
          request.send(tag)
        else
          tag
        end
      end
    end

    def finish(request, body)
      instrumenter = ActiveSupport::Notifications.instrumenter
      instrumenter.finish "request.action_dispatch", request: request
      @log = (@lines || []).join("\n")

      if send_request?(request)
        unless body.is_a?(String)
          body = body.to_a rescue [body.body] rescue "No body given"
        end

        if body.respond_to?(:each)
          @output = []
          body.each do |line|
            @output << line
          end
          @output = @output.join("\n")
        else
          @output = body.to_s
        end

        puts @log

        @log ||= "None found"
        @output ||= "None found"
        @status ||= "-"

        tags = ActiveTracker::Plugin::Request.current_tags.dup
        tags[:status] = @status
        tags[:duration] = "#{@time_taken.to_i}ms"
        tags[:url] = request.fullpath
        tags[:method] = request.request_method
        tags[:app] = app_name
        # Move these to the apps
        # tags[:email] = request.headers["X-CivoCom-User-Email"] if request.headers["X-CivoCom-User-Email"].present?
        # tags[:civocom_request_path] = request.headers["X-CivoCom-Request-Path"] if request.headers["X-CivoCom-Request-Path"].present?
        # tags[:civocom_request_id] = request.headers["X-CivoCom-RequestID"] if request.headers["X-CivoCom-RequestID"].present?
        tags[:id] = request.uuid || SecureRandom.uuid

        ActiveTracker::Model.save("Request", {log: @log[0, 65535], output: @output},
          tags: tags, data_type: "output", expiry: 7.days, log_at: Time.current)
      end

      if Rails.env.development? || Rails.env.test?
        File.open("#{Rails.root}/log/#{Rails.env}.log", "a") do |f|
          f << @log
        end
      end

    ensure
      @recording = false
    end

    def send_request?(request)
      ActiveTracker::Plugin::Request.filters.each do |filter|
        if filter.is_a?(Regexp)
          if filter.match(request.fullpath)
            return false
          end
        else
          if request.fullpath.start_with?(filter)
            return false
          end
        end
      end

      true
    end

    def logger
      self
    end
  end
end
