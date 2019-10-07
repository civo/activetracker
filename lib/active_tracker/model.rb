require 'json'

module ActiveTracker
  class Model
    PREFIX = "/ActiveTracker".freeze

    def self.find(key)
      connection = ActiveTracker.connection
      value = connection.get(key)
      if value.nil?
        raise NotFound.new("Couldn't find entry - #{key}")
      else
        if value.start_with?(PREFIX)
          find(value)
        else
          self.new(key, value)
        end
      end
    end

    def self.all(type, tags: {}, data_type: nil)
      keys = "#{PREFIX}/#{type}/"

      keys += "*"

      tags.sort_by { |k,v| k.to_s }.each do |k,v|
        keys += "#{k}:#{CGI.escape(v.to_s)}/*"
      end

      if data_type
        keys += "/#{data_type}"
      end

      connection = ActiveTracker.connection
      result = connection.keys(keys).sort { |a,b| b <=> a }.map { |key| self.new(key, {}.to_json) }
    end

    def self.save(type, data, tags: {}, data_type: nil, expiry: 7.days, log_at: Time.current)
      key = PREFIX + "/#{type}/#{log_at.strftime("%Y%m%d%H%M%S")}"
      converted_tags = tags.sort_by { |k,v| k.to_s }.map {|k,v| "#{k}:#{CGI.escape(v.to_s)}"}
      if converted_tags.any?
        key = key + "/" + converted_tags.join("/")
      end
      key += "/#{data_type}"
      key.gsub!(%r{/{2,}}, '/')
      value = data.to_json
      connection = ActiveTracker.connection
      connection.set(key, value)
      connection.expire(key, expiry)
      connection.set(tags[:id], key)
      connection.expire(tags[:id], expiry)
      key
    end

    def self.paginate(items, page, per_page)
      page = (page || 1).to_i

      total = items.length
      start_point = (page - 1) * per_page

      items = items[start_point, per_page]

      total_pages = total / per_page
      total_pages += 1 if (total % per_page != 0)

      window = []
      window << page - 2 if page > 2
      window << page - 1 if page > 1
      window << page
      window << page + 1 if (total_pages - page) > 0
      window << page + 2 if (total_pages - page) > 1

      [items, {total: total, total_pages: total_pages, page: page, window: window}]
    end

    def initialize(key, value)
      @attrs = {key: key}
      key.gsub!(/^A#{PREFIX}/, "")
      parts = key.split("/")
      _ = parts.shift # Starts with a /
      _ = parts.shift # then comes PREFIX
      @attrs[:type] = parts.shift
      @attrs[:data_type] = parts.pop
      @attrs[:log_at] = Time.parse(parts.shift)
      @attrs[:tags] = {}
      parts.sort.each do |part|
        tag_name, tag_value = part.split(":")
        if tag_name == "id"
          @attrs[:id] = tag_value
        else
          @attrs[:tags][tag_name.to_sym] = CGI.unescape(tag_value)
        end
      end
      value = JSON.parse(value)
      value.each do |key, value|
        self.send("#{key}=", value)
      end
    end

    def method_missing(name, value = nil)
      if name.to_s.end_with?("=")
        @attrs[name.to_s.gsub("=", "").to_sym] = value
      else
        @attrs[name]
      end
    end

    class NotFound < ActiveTracker::Error ; end
  end
end
