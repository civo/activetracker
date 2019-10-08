# ActiveTracker

ActiveTracker is a Ruby gem that you install to your application to track user requests through your logs, see errors raised, queue usage/failures along with other things configured via a plugin architecture.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activetracker'
```

And then execute:

    $ bundle

Then run:

    $ bundle exec rails activetracker:install

## Configuration

After you run the `rails activetracker:install` command, you will have a file called `activetracker.rb` in `config/initializers`. This file controls which ActiveTracker plugins are enabled and configuring ActiveTracker as a whole as well as each individual plugin.

Configuring the list of plugins is as easy as listing them:

```
ActiveTracker::Configuration.plugins = [
  ActiveTracker::Plugin::Request,
  ActiveTracker::Plugin::Exception,
]
```

This will enable any Rails integration necessary and add them to the left bar.

ActiveTracker stores its data in Redis. We recommend a separate Redis installation for this, with a memory limit set and configured to automatically delete least recently used items - like this:

```
maxmemory 250mb
maxmemory-policy allkeys-lru
```

You should point ActiveTracker to your Redis server within the `activetracker.rb` initializer with:

```
ActiveTracker::Configuration.redis_url = "redis://localhost:6379/15"
```

If you don't like the default number of items per page in ActiveTracker, you can change it with:

```
ActiveTracker::Configuration.per_page = 50
```

You can choose to have ActiveTracker available anywhere if you don't like the default of `/activetracker`:

```
ActiveTracker::Configuration.mountpoint = "debugger"
```

If you want to setup authentication for your installation:

```
ActiveTracker::Configuration.authentication = "username:password"

# or using a proc:

ActiveTracker::Configuration.authentication do
  false unless params[:password] == "password"
end
```

The first example uses HTTP Basic authentication and the latter will reject unauthenticated requests with 404 (so as not to give away its existence). These are executed in the context of a controller, but it doesn't descend from ApplicationController, so you can't use any authentication methods defined there (if you wish to `extend` or `include` them on `ActiveTracker::BaseController` you can though).

## Individual plugins

* [Request](doc/request.md)
* TODO

## Writing plugins

If you would like to write a plugin, the easiest example to copy is ... TODO

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/civo/activetracker.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
