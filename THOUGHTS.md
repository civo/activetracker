# Key concepts

* Everything is a plugin (even built in stuff)
* Pull tailwindcss and something jquery-like from a CDN
* Store in Redis, default to 7 days expiry - keys are in the following format:
  `/ActiveTracker/PluginName/YYYYMMDDHHIISS/tag/tag/data-type`

  e.g.:

  `/ActiveTracker/Request/20190927194300/id:e52c5517-eb46-4ba5-be56-90aa7436f26a/path:%2Flogin%3Ffoo/method:get/summary`

* By default plugins should hook in to Rails if enabled, not require any other action

## Configuration

```ruby
ActiveTracker::Configuration.plugins = [
  ActiveTracker::Plugin::Request, # Entire request log, with response
  ActiveTracker::Plugin::Schedule, # When a scheduled job is queued
  ActiveTracker::Plugin::Exception, # When an exception is raised
  ActiveTracker::Plugin::ActiveJob, # When a job is processed, with output
  ActiveTracker::Plugin::ActionMail, # When an email is sent, with the body
  ActiveTracker::Plugin::Event, # Random events triggered in the system
  ActiveTracker::Plugin::ActiveRecord, # Queries performed with ms taken
]

# Configure who can access the system - you have access to the request,
# session and cookies here, as it executes in a session
ActiveTracker::Configuration.authentication = -> { Current.user&.admin? }

# Apply a filter on which URL requests should be captured
ActiveTracker::Plugin::Request.append_filter -> { |req| req.url["/ping"] }
```

## Usage in code

```ruby
# Trigger a random event
ActiveTracker::Plugin::Event.trigger("webhook.something", {data: "here"})

# Mark a job as having been cron-scheduled
ActiveTracker::Plugin::Schedule.trigger(job)

# Tag the current request with a key and value (both are strings/string-like)
ActiveTracker::Plugin::Request.tag(key, value)
```
