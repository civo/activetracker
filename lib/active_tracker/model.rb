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

    def self.delete(key)
      ActiveTracker.connection.del(key)
    end

    def self.all(type, tags: {}, data_type: nil)
      keys = "#{PREFIX}/#{type}/"

      keys += "*"

      keys += tags.sort_by { |k,v| k.to_s }.map do |k,v|
        "#{k}:#{CGI.escape(v.to_s)}"
      end.join("*")

      keys += "*"

      if data_type
        keys += "/#{data_type}"
      end

      connection = ActiveTracker.connection
      result = connection.keys(keys).sort { |a,b| b <=> a }.map { |key| self.new(key, {}.to_json) }
    end

    def self.generate_key(type, log_time, tags, data_type)
      key = PREFIX + "/#{type}/#{log_time}"
      converted_tags = tags.sort_by { |k,v| k.to_s }.map {|k,v| "#{k}:#{CGI.escape(v.to_s)}"}
      if converted_tags.any?
        key = key + "/" + converted_tags.join("/")
      end
      key += "/#{data_type}"
      key.gsub!(%r{/{2,}}, '/')
      key
    end

    def self.save(type, data, tags: {}, data_type: nil, expiry: 7.days, log_at: Time.current)
      if log_at.respond_to?(:strftime)
        log_time = log_at.strftime("%Y%m%d%H%M%S")
      else
        log_time = log_at
      end
      key = generate_key(type, log_time, tags, data_type)
      value = data.to_json
      connection = ActiveTracker.connection
      connection.set(key, value)
      connection.expire(key, expiry)
      if tags[:id].present?
        connection.set(tags[:id], key)
        connection.expire(tags[:id], expiry)
      end
      key
    end

    def self.find_or_create(type, tags: {}, data_type: nil)
      keys = all(type, tags: tags, data_type: data_type)
      if keys.length > 0
        obj = find(keys.first.key) rescue nil
      end

      if !obj
        obj = new(generate_key(type, "-", tags, data_type), {}.to_json, false)
      end
      yield obj
      obj.save
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

    def initialize(key, value, persisted = true)
      @attrs = {key: key, persisted: persisted}
      key.gsub!(/^A#{PREFIX}/, "")
      parts = key.split("/")
      _ = parts.shift # Starts with a /
      _ = parts.shift # then comes PREFIX
      @attrs[:type] = parts.shift
      @attrs[:data_type] = parts.pop
      t = parts.shift
      @attrs[:log_at] = Time.parse(t) rescue t
      @attrs[:tags] = {}
      parts.sort.each do |part|
        tag_name, tag_value = part.split(":")
        if tag_name == "id"
          @attrs[:id] = tag_value
        else
          @attrs[:tags][tag_name.to_sym] = CGI.unescape("#{tag_value}")
        end
      end
      value = JSON.parse(value)
      self.send("data=", value)
      value.each do |key, value|
        self.send("#{key}=", value)
      end
    end

    def save
      self.class.save(@attrs[:type], data, tags: {id: id}.merge(@attrs[:tags]), data_type: @attrs[:data_type], expiry: expiry, log_at: log_at)
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
