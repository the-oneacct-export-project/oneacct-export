require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = { :namespace => 'one_queue', :size => 1 }
end
Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'one_queue' }
end

