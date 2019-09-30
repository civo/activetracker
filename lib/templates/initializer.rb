# Which plugins are active. The full list installed by default is:
# * ActiveTracker::Plugin::Request       # Entire request log, with response
# * ActiveTracker::Plugin::Schedule      # When a scheduled job is queued
# * ActiveTracker::Plugin::Exception     # When an exception is raised
# * ActiveTracker::Plugin::ActiveJob     # When a job is processed, with output
# * ActiveTracker::Plugin::ActionMail    # When an email is sent, with the body
# * ActiveTracker::Plugin::Event         # Random events triggered in the system
# * ActiveTracker::Plugin::ActiveRecord  # Queries performed with ms taken

ActiveTracker::Configuration.plugins = [
  ActiveTracker::Plugin::Request,
  ActiveTracker::Plugin::Exception,
]

ActiveTracker::Configuration.redis_url = "redis://localhost:6379/15"

Rails.application.config.assets.precompile += %w( active_tracker/active_tracker.js active_tracker/active_tracker.css )
