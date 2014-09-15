require 'settings'
require 'uri'
require 'input_validator'

class RedisConf
  extend InputValidator

  def self.options
    options = {}
    if Settings['redis']
      options[:namespace] = Settings.redis['namespace']
      options[:url] = Settings.redis['url']
    end

    options[:namespace] ||= 'oneacct_export'
    options[:url] ||= 'redis://localhost:6379'

    fail ArgumentError, "#{options[:url]} is not a valid URL."\
      unless is_uri?(options[:url])

    if Settings['redis'] && Settings.redis['password']
      fail ArgumentError, 'Redis password cannot be empty'\
        if Settings.redis['password'].empty?
      options[:url].insert(options[:url].index('/') + 2, ":#{Settings.redis['password']}@")
    end

    options
  end
end
