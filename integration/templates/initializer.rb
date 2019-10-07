# Which plugins are active. The full list installed by default is:
#
# ActiveTracker::Plugin::Request       # Entire request log, with response
# ActiveTracker::Plugin::Schedule      # When a scheduled job is queued
# ActiveTracker::Plugin::Exception     # When an exception is raised
# ActiveTracker::Plugin::ActiveJob     # When a job is processed, with output
# ActiveTracker::Plugin::ActionMail    # When an email is sent, with the body
# ActiveTracker::Plugin::Event         # Random events triggered in the system
# ActiveTracker::Plugin::ActiveRecord  # Queries performed with ms taken

ActiveTracker::Configuration.plugins = [
  ActiveTracker::Plugin::Request,
  ActiveTracker::Plugin::Exception,
]

# You should change this to be your correct Redis URL
ActiveTracker::Configuration.redis_url = "redis://localhost:6379/15"

# By default ActiveTracker is mounted at /activetracker
# if you'd like to change it, you can do so like this:
# ActiveTracker::Configuration.mountpoint = "debugger"

# If you want to authenticate requests to ActiveTracker with username and password
# ActiveTracker::Configuration.authentication = "username:password"
# or using a proc:
# ActiveTracker::Configuration.authentication do
#   false unless params[:password] == "password"
# end

