require 'settingslogic'

class Settings < Settingslogic
  CONF_NAME = 'conf.yml'

  source "#{ENV['HOME']}/.oneacct-export/#{CONF_NAME}"\
    if File.exist?("#{ENV['HOME']}/.oneacct-export/#{CONF_NAME}")
  source "/etc/oneacct-export/#{CONF_NAME}"\
    if File.exist?("/etc/oneacct-export/#{CONF_NAME}")
  source "#{File.dirname(__FILE__)}/../config/#{CONF_NAME}"

  namespace ENV['RAILS_ENV'] ? ENV['RAILS_ENV'] : 'production'
end
