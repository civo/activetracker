module ActiveTracker
  module ImagesHelper
    def activetracker_inline_svg(image)
      svg = File.read(ActiveTracker::Engine.root.join('app', 'assets', 'images', image))
      svg.html_safe
    end
  end
end
