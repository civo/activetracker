module ActiveTracker
  class ExceptionCapturer
    def initialize(app)
      @app = app
    end

    def call(env)

      response = @app.call(env)

      framework_exception = env['action_dispatch.exception']
      if framework_exception
        record_exception(env, framework_exception)
      end

      response
    rescue Exception => exception

      record_exception(env, exception)
      raise exception
    end

    def record_exception(env, exception)
      if env['action_dispatch.backtrace_cleaner']
        backtrace = env['action_dispatch.backtrace_cleaner'].filter(exception.backtrace)
        backtrace = exception.backtrace if backtrace.blank?
      else
        backtrace = exception.backtrace
      end
      class_name = exception.class.name
      message = exception.message
      backtrace = backtrace || []

      ActiveTracker::Plugin::Exception.exception_capture(class_name, message, backtrace)
    end

  end
end
