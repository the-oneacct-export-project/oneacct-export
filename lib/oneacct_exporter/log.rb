require 'logger'

class OneacctExporter
  module Log
    def self.setup_log_level(logger)
      if ENV['ONEACCT_EXPORT_LOG_LEVEL'] and Logger::Severity.const_defined? ENV['ONEACCT_EXPORT_LOG_LEVEL']
        logger.level = Logger::Severity.const_get ENV['ONEACCT_EXPORT_LOG_LEVEL'] 
      else
        logger.level = Logger::INFO
      end

      logger
    end
  end
end

