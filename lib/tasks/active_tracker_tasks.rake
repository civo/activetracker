# desc "Explaining what the task does"
# task :active_tracker do
#   # Task goes here
# end

namespace :activetracker do
  desc 'install initial files'
  task :install do
    installer_template = File.expand_path("../rails/generators/installer.rb", __dir__)
    system "#{RbConfig.ruby} ./bin/rails app:template LOCATION=#{installer_template}"
  end
end
