RSpec.describe ActiveTracker do
  before do
    ActiveTracker.reset_connection
  end

  it "has a version number" do
    expect(ActiveTracker::VERSION).not_to be nil
  end

  it "creates a new connection to redis" do
    ActiveTracker::Configuration.redis_url = "foo"
    expect(Redis).to receive(:new).with(url: "foo")
    ActiveTracker.connection
  end

  it "pings and returns an existing connection to redis" do
    connection = double("Redis")
    expect(Redis).to receive(:new).with(url: "foo").and_return(connection)
    ActiveTracker.connection

    expect(Redis).to_not receive(:new)
    expect(connection).to receive(:ping).and_return("PONG")
    ActiveTracker.connection
  end

  it "re-connects to Redis if a ping fails" do
    ActiveTracker::Configuration.redis_url = "foo"
    connection = double("Redis")
    allow(Redis).to receive(:new).with(url: "foo").and_return(connection)
    ActiveTracker.connection

    expect(connection).to receive(:ping).and_raise(StandardError.new("Down"))
    expect(Redis).to receive(:new)
    ActiveTracker.connection
  end
end
