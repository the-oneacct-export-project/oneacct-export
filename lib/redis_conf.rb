require 'settings'

class RedisConf

  def self.options
    options = {}
    if Settings['redis']
      options[:namespace] = Settings.redis['namespace']
      options[:url] = Settings.redis['url']
    end

    options[:namespace] ||= "oneacct_export"
    options[:url] ||= "redis://localhost:6379"

    options[:url].insert(8, ":#{Settings.redis['password']}@") if Settings['redis'] and Settings.redis['password']

    options
  end
end
