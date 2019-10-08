module ActiveTracker
  module OutputHelper
    def escape_ansi(data)
      { 1 => :nothing,
        2 => :nothing,
        4 => :nothing,
        5 => :nothing,
        7 => :nothing,
        30 => :black,
        31 => :red,
        32 => :green,
        33 => :yellow,
        34 => :blue,
        35 => :magenta,
        36 => :cyan,
        37 => :white,
        40 => :nothing,
        41 => :nothing,
        43 => :nothing,
        44 => :nothing,
        45 => :nothing,
        46 => :nothing,
        47 => :nothing,
      }.each do |key, value|
        if value != :nothing
          data.gsub!(/\e\[#{key}m/,"<span style=\"color:#{value}\">")
        else
          data.gsub!(/\e\[#{key}m/,"<span>")
        end
      end
      data.gsub!(/\e\[0m/,'</span>')
      return sanitize(data, tags: %w{span}, attributes: %w{style}).html_safe
    end
  end
end
