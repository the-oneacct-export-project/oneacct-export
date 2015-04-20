require 'settingslogic'

# Class representing OneacctExport settings
class Settings < Settingslogic
  CONF_NAME = 'conf.yml'

  # three possible configuration file locations in order by preference
  # if configuration file is found rest of the locations are ignored
  source "#{ENV['HOME']}/.oneacct-export/#{CONF_NAME}"\
    if File.exist?("#{ENV['HOME']}/.oneacct-export/#{CONF_NAME}")
  source "/etc/oneacct-export/#{CONF_NAME}"\
    if File.exist?("/etc/oneacct-export/#{CONF_NAME}")
  source "#{File.dirname(__FILE__)}/../config/#{CONF_NAME}"

  namespace ENV['RAILS_ENV'] ? ENV['RAILS_ENV'] : 'production'
end
