require 'settings'
require 'uri'
require 'input_validator'

# Class that deals with Redis server configuration options
class RedisConf
  extend InputValidator

  # Read and parse Redis server configuration options
  #
  # @return [Hash] redis server options ready for use
  def self.options
    options = {}
    if Settings['redis']
      options[:namespace] = Settings.redis['namespace']
      options[:url] = Settings.redis['url']
    end

    options[:namespace] ||= 'oneacct_export'
    options[:url] ||= 'redis://localhost:6379'

    fail ArgumentError, "#{options[:url]} is not a valid URL."\
      unless uri?(options[:url])

    if Settings['redis'] && Settings.redis['password']
      fail ArgumentError, 'Redis password cannot be empty'\
        if Settings.redis['password'].empty?
      options[:url].insert(options[:url].index('/') + 2, ":#{Settings.redis['password']}@")
    end

    options
  end
end
