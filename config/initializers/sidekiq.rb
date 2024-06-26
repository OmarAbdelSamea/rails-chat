# TODO: update the configuration to use the redis server
sidekiq_config = { url: "redis://localhost:6360/12" }

Sidekiq.configure_server do |config|
    config.redis = sidekiq_config
end

Sidekiq.configure_client do |config|
    config.redis = sidekiq_config
end