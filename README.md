# ActiveTracker

ActiveTracker is a Ruby gem implementing an engine that you add to your Rails application to track user requests through your logs, see errors raised, query usage along with other things configured via a plugin architecture.

![Overview of ActiveTracker](https://user-images.githubusercontent.com/22904/67408234-9edf6300-f5b0-11e9-8eb5-eda79642e15f.png)

## Contents

* [Installation](#installation)
    * [Quickstart](##tldr---quickstart)
* [Configuration](#configuration)
* [Request plugin](#request-plugin)
    * [Filters](#filters)
    * [Tagging your own requests](#tagging-your-own-requests)
    * [Redaction](#redaction)
* [Query plugin](#query-plugin)
    * [Filters](#filters-1)
    * [Slow queries](#slow-queries)
* [Exception plugin](#exception-plugin)
    * [Filters](#filters-2)
* [Upcoming plans](#upcoming-plans)
* [Writing plugins](#writing-plugins)
    * [The plugin itself](#1-the-plugin-itself)
    * [Controller and views](#2-controllers-and-views)
* [How can I help?](#how-can-i-help)
* [Contributing](#contributing)
* [Licence](#licence)


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activetracker'
```

And then execute:

    $ bundle

Then run:

    $ bundle exec rails activetracker:install

After this you can run your Rails application and visit http://your-host/activetracker to see ActiveTracker's capturing of your requests, etc.

### TL;DR - Quickstart

```sh
echo "gem 'activetracker'" >> Gemfile
bundle
bundle exec rails activetracker:install
rails s
# Then open http://localhost:3000/activetracker and hit other pages
# on your site
```

## Configuration

After you run the `rails activetracker:install` command, you will have a file called `activetracker.rb` in `config/initializers`. This file controls which ActiveTracker plugins are enabled and configuring ActiveTracker as a whole as well as each individual plugin.

#### Selecting plugins

Configuring the list of plugins is as easy as listing them:

```
ActiveTracker::Configuration.plugins = [
  ActiveTracker::Plugin::Request,
  ActiveTracker::Plugin::Exception,
]
```

This will enable any Rails integration necessary and add them to ActiveTracker's sidebar.

#### Redis

ActiveTracker stores its data in Redis. We recommend a separate Redis installation for this, with a memory limit set and configured to automatically delete least recently used items - put some lines like this in your Redis configuration file:

```
maxmemory 250mb
maxmemory-policy allkeys-lru
```

You should point ActiveTracker to your Redis server within the `activetracker.rb` initializer with:

```
ActiveTracker::Configuration.redis_url = "redis://localhost:6379/15"
```

#### Pagination

If you don't like the default number of items per page in ActiveTracker, you can change it with:

```
ActiveTracker::Configuration.per_page = 50
```

#### Different mountpoint

You can choose to have ActiveTracker available anywhere if you don't like the default of `/activetracker`:

```
ActiveTracker::Configuration.mountpoint = "debugger"
```

#### Authentication

If you want to setup authentication for your installation:

```
ActiveTracker::Configuration.authentication = "username:password"

# or using a proc:

ActiveTracker::Configuration.authentication do
  false unless params[:password] == "password"
end
```

The first example uses HTTP Basic authentication and the latter will reject unauthenticated requests with 404 (so as not to give away its existence). These are executed in the context of a controller, but it doesn't descend from ApplicationController, so you can't use any authentication methods defined there (if you wish to `extend` or `include` them on `ActiveTracker::BaseController` you can though).

## Request plugin

<img width="400" alt="Screenshot 2019-10-23 at 16 19 14" src="https://user-images.githubusercontent.com/22904/67408530-0d242580-f5b1-11e9-9d64-51bf52125978.png"> <img width="400" alt="Screenshot 2019-10-23 at 16 19 20" src="https://user-images.githubusercontent.com/22904/67408531-0d242580-f5b1-11e9-8cb6-62c81a84936f.png">

> The request plugin captures the log and output from every request your Rails application receives.

There is a limit of 64KB for the log, but the full output is captured for every request.

#### Filters

You can filter requests from being captured by adding to the `activetracker` initializer lines like:

```ruby
ActiveTracker::Plugin::Request.filters << /foobar/
# or 
ActiveTracker::Plugin::Request.filters += "/foobar"
# or replace them entirely with
ActiveTracker::Plugin::Request.filters = ["/foobar"]
```

By default ActiveTracker itself is filtered out. If a string is supplied it must match the start of the path of the request, not just any portion. Regular expression filters are applied against the whole path.

#### Tagging your own requests

During a request cycle you can add custom tags to requests by putting lines like this in your controller, model, helper, service, etc:

```
ActiveTracker::Plugin::Request.tag_current(key: value, key2: value2)
```

These tags are then shown alongside every request, and if you click the tag you can filter the requests down to only those matching that tag(s).

The tag names `user_avatar_url`, `user_name` and `user_email` have special meaning, if you set these tags, they will be displayed alongside the request in a nice format when you view it (see "Test McPerson" in the right hand screenshot above).

#### Redaction

The easiest way of ensuring values such as passwords in the log and output aren't leaked to ActiveTracker is to tell ActiveTracker to explicitly redact that value. For example, in your controller:

```
def login
  ActiveTracker::Plugin::Request.redact(Current.user.password_hash)
  ActiveTracker::Plugin::Request.redact(params[:password])
end
```

These are cleared upon each request.

## Query plugin

<img width="400" alt="Screenshot 2019-10-24 at 08 55 40" src="https://user-images.githubusercontent.com/22904/67464913-1a3a2680-f63c-11e9-9ba8-e1d28fcfa54f.png"> <img width="400" alt="Screenshot 2019-10-24 at 08 55 45" src="https://user-images.githubusercontent.com/22904/67464921-1c03ea00-f63c-11e9-95dc-568d5d8754ce.png">

> The query plugin saves a count for each SQL query executed and how long it took, to enable you to find queries executed too often or queries you consider to be too slow for your application.

#### Filters

You can filter queries from being captured by adding to the `activetracker` initializer lines to search both the SQL and the ActiveRecord `name` of the query (e.g. `Order Load`) like this:

```ruby
ActiveTracker::Plugin::Query.filters << /secret_records/
# or 
ActiveTracker::Plugin::Query.filters += "secret_records"
# or replace them entirely with
ActiveTracker::Plugin::Query.filters = ["secret_records"]
```

By default ActiveTracker filters out queries containing either `SCHEMA` or an empty value. These values are searched anywhere in the SQL or `name`.

#### Slow queries

You can configure a threshold of how slow a query has to be before it's highlighted with a red time value using:

```ruby
ActiveTracker::Plugin::Query.min_slow_duration_ms = 25
```

By default this is set to 100ms, but this is probably too loose for most applications.

## Exception plugin

<img width="400" alt="Screenshot 2019-10-24 at 09 03 53" src="https://user-images.githubusercontent.com/22904/67465517-3ee2ce00-f63d-11e9-8395-104ec31f046e.png"> <img width="400" alt="Screenshot 2019-10-24 at 09 03 59" src="https://user-images.githubusercontent.com/22904/67465525-42765500-f63d-11e9-82b1-e2b904c20025.png">

> The exception plugin tracks unhandled exceptions, incrementing a counter for them and keeping a backtrace to where the error occured.

#### Filters

You can filter certain exceptions from being captured by adding to the `activetracker` initializer lines to specify a class name like this:

```ruby
ActiveTracker::Plugin::Query.filters << ActiveRecord::RecordNotFound
# or 
ActiveTracker::Plugin::Query.filters += "ActiveRecord::RecordNotFound"
# or replace them entirely with
ActiveTracker::Plugin::Query.filters = [/.*RecordNotFound/]
```

There are no exception filters by default. Strings and classes have to be exact matches, but regular expressions match against the name normally.

## Upcoming plans

The next set of plugins we're planning on writing are:

#### Resque

Statistics for current queue lengths and current amounts of failed jobs. Clicking the sidebar will list jobs on each queue and failed jobs - just like the Resque Web UI but all in the same place as your other ActiveTracker monitoring panes.

#### Mail

Recording when emails are sent from your system, along with their body for easy previewing of what was sent and when.

#### Cache

Using Rails notifications track cache hits and misses for each key.

#### Events

We'd like a simple system of triggering events from within the your application that simply are recorded to ActiveTracker. So maybe a key, a description and a backtrace would be enough?

## Writing plugins

If you would like to write a plugin, there is a minimum set of code you need to write. In our example we're going to write a "Fake" plugin.

### 1. The plugin itself

A plain Ruby object on the path (in ActiveTracker these live in `lib/active_tracker/plugin`) namespaced under `ActiveTracker::Plugin`.  The minimum methods this should implement are:

```ruby
module ActiveTracker
  module Plugin
    class Fake < Base
      def self.register
        # Subscribe to Notifications
        # Insert Rails middleware
        # Hook in to Rails/gem internals

        @@registered = true
      end

      def self.registered?
        @@registered rescue false
      end

      def self.resources_name
        # return a symbol for use in config/routes.rb like:
        # resources resources_name
      end

      def self.nav_svg
        # return the HTML safe source of an SVG image with a class 
        # specified of 'fill-current' and 16x16 dimensions. Don't 
        # specify the colour on the paths, they should be monochrome
      end

      def self.nav_title
        # return a string containing the title to use in the sidebar
      end

      def self.statistics
        # Return an array of hashes containing keys of:
        # {plugin: self, label: "Something", value: 1}
        # if the statistic is bad, add a key of `error: true`
        # 
        # if you don't report statistics, don't implement this method
      end
    end
  end
end
```

The hooks/notifications/middleware/etc should insert records in to the `ActiveTracker::Model` using a couple of simple methods. If you are recording EVERY occurence of this event:

```ruby
# Type of object, JSON of the data for this object, tags are a hash of
# keys and values that can be useful for filtering. Data type is if you
# are saving multiple objects for each Fake.
ActiveTracker::Model.save("Fake", {output: output},
  tags: {my_value: something.value},
  data_type: "full",
  expiry: 7.days,
  log_at: Time.now
)
```

Or if you only want to track the latest one, but count all of them, you could do it like this:

```ruby
ActiveTracker::Model.find_or_create("Fake", tags:tags, data_type: "full") do |obj|
  if obj.persisted
    ActiveTracker::Model.delete(obj.key)
  end
  obj.data ||= {}
  obj.data["count"] = (obj.data["count"] || 0) + 1

  obj.data["output"] = output
end
```

### 2. Controller and views

You should implement an `ActiveTracker::FakesController` that implements the normal RESTful endpoints. A barebones example of how to write this would be something like:

```ruby
module ActiveTracker
  class FakesController < ActiveTracker::BaseController
    def index
      # Track how long this request takes
      ts = Time.current.to_f
      # Get all matching records from the model
      @fakes = ActiveTracker::Model.all("Fake")
      # If you're providing filtering, use a method to reduce the recordset
      filter_fakes if params[:q].present?
      # Finish tracking this request's duration
      @duration = (Time.current.to_f - ts) * 1000
      # Paginate the objects
      @fakes, @pagination = ActiveTracker::Model.paginate(@fakes, params[:page], ActiveTracker::Configuration.per_page)
    end

    def show
      # Find the fake from the model
      @request = ActiveTracker::Model.find(params[:id])
    end

    private

    def filter_requests
      # Go through each record in @fakes determining whether to select/reject
      # it or not, based on params[:q] and reset @fakes to the new set 
      # if needed
    end
  end
end
```

For styling, have a look at the Tailwind classes used in the views for other plugins and try to maintain consistent styling - unless you're willing to upgrade all other plugins ;-)

Once you've written your plugin, you can add it to `integration/templates/initializer.rb` either uncommented if it will be a new default plugin, or at least to the comment block at the top for available plugins.

## How can I help?

The most obvious way to help is by jumping in and raising issues, creating your own plugins (we'll list them here when people start doing that, or maybe integrate them in to this repository if people want to just donate them and they have wide appeal).

However, if you are looking for a way to help out but don't have any ideas, we've listed a few below that we'd appreciate some help with (we'll hopefully get to all of them over time, but have our own list above that we're planning on first):

#### Webpacker

Currently ActiveTracker uses the asset pipeline. We'd love it if it would work with Webpacker or the asset pipeline (and maybe it already does), whichever the containing project is using.

#### Ajax loading of results

We would love to have it Ajaxified so if you stay on the page (and maybe click a button to enable the feature) it automatically puts a banner bar at the top of results saying "New requests/queries/whatever available" and if you click it, the new entries will be Ajax loaded in.

#### Automated testing

Having no experience of automated testing a Rails engine, if anyone fancies putting in some testing for us - we'd *LOVE* that!

#### Responsive

We chose [Tailwind CSS](https://tailwindcss.com) because it's lovely to work with and you can quickly/easily put together fairly nice interfaces. It's also built to be responsive, but as this is a small, spare time project for us we haven't had chance to do this yet.

#### Dark mode

Some of our team love dark displays, but the main author of this gem doesn't. So while we'd love to have it, it's not high enough on the priority list to justify at the moment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/civo/activetracker.

## Licence

The gem is available as open source under the terms of the [MIT Licence](https://opensource.org/licenses/MIT). The [ActiveTracker logo](doc/logo.md) was an icon downloaded from LogoFound.com and combined with the name in Helvetica Neue.
