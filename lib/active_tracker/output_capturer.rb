module ActiveTracker
  class OutputCapturer
    def initialize(app, taggers = nil)
      @app         = app
      @taggers     = taggers || []
    end

    def call(env)
      start_time = Time.current
      status, headers, response = @app.call(env)
      capture(response)
      duration = (Time.current.to_f - start_time.to_f) * 1000
      ActiveTracker::Plugin::Request.record_duration(duration)
      [status, headers, response]
    end

    def capture(response)
      body = response.body rescue nil
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

      ActiveTracker::Plugin::Request.output_capture(output)
    end

  end
end