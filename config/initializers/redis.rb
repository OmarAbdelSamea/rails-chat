require 'redis'
# TODO: update the configuration to use the redis server
redis_config = { url: "redis://localhost:6360/12" }

begin
    $redis = Redis.new(redis_config)
    $red_lock = Redlock::Client.new(["redis://localhost:6360"])
rescue Exception => e
    puts e
end