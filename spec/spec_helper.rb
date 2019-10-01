require "bundler/setup"
require "active_support"
require "fakeredis"
require "timecop"
require "activetracker"

class Rails
  def self.const_missing(key)
    self
  end

  def self.method_missing(key, *args)
    self
  end

  def method_missing(key, *args)
    self
  end
end

module Rack
  def self.const_missing(key)
    self
  end

  def self.method_missing(key, *args)
    self
  end

  def method_missing(key, *args)
    self
  end
end

(Dir["#{File.dirname(__FILE__)}/../lib/**/*.rb"] - Dir["#{File.dirname(__FILE__)}/../lib/templates/**/*.rb"]).each{|f| require_relative(f)}

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
