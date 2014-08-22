require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = { :namespace => 'oneacct_export', :size => 1 }
end
Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'oneacct_export' }
end

