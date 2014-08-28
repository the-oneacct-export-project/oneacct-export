require 'settings'
require 'uri'

class RedisConf
  URL_RE = /\A#{URI.regexp}\z/

  def self.options
    options = {}
    if Settings['redis']
      options[:namespace] = Settings.redis['namespace']
      options[:url] = Settings.redis['url']
    end

    options[:namespace] ||= 'oneacct_export'
    options[:url] ||= 'redis://localhost:6379'

    fail ArgumentError, "#{options[:url]} is not a valid URL."\
      unless options[:url] =~ URL_RE

    if Settings['redis'] && Settings.redis['password']
      fail ArgumentError, 'Redis password cannot be empty'\
        if Settings.redis['password'].empty?
      options[:url].insert(8, ":#{Settings.redis['password']}@")
    end

    options
  end
end
