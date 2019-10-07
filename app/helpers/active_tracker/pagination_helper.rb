module ActiveTracker
  module PaginationHelper
    def insert_page_to_url(url, page)
      if url.include?("?")
        if url[/[?&]page=/]
          url = url.gsub(/([?&]page)=\d+/, "\\1=#{page}")
        else
          url += "&page=#{page}"
        end
      else
        url += "?page=#{page}"
      end
      url
    end
  end
end
