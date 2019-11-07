module ActiveTracker
  class OutputCapturer
    def initialize(app)
      @app         = app
    end

    def call(env)
      start_time = Time.current
      status, headers, response = @app.call(env)
      [status, headers, response]
    ensure
      capture(response, headers)
      duration = (Time.current.to_f - start_time.to_f) * 1000
      ActiveTracker::Plugin::Request.record_duration(duration)
    end

    def capture(response, headers)
      if response.respond_to?(:body)
        body = response.body rescue nil
      else
        body = response
      end

      unless body.is_a?(String)
        body = body.to_a rescue [body.body] rescue "No body given"
      end

      if body.respond_to?(:each)
        output = []
        body.each do |line|
          output << line
        end
        output = output.join("\n")
      else
        output = body.to_s
      end

      ActiveTracker::Plugin::Request.output_capture(output, headers["Content-type"])
    end

  end
end
