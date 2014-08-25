require 'sidekiq'
require 'redis_conf'

Sidekiq.configure_client do |config|
  options = RedisConf.options
  options[:size] = 1
  config.redis = options
end
Sidekiq.configure_server do |config|
  config.redis = RedisConf.options
end
