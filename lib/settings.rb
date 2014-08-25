require 'settingslogic'

class Settings < Settingslogic
  CONF_NAME = "conf.yml"

  source "config/#{CONF_NAME}"

  def self.choose_config
    config = "config/#{CONF_NAME}"
    config = "/etc/oneacct-export/#{CONF_NAME}" if File.exist?("/etc/oneacct-export/#{CONF_NAME}")
    config = "#{ENV['HOME']}/.oneacct-export/#{CONF_NAME}" if File.exist?("#{ENV['HOME']}/.oneacct-export/#{CONF_NAME}")

    config
  end
end
