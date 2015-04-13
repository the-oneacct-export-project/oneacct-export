require 'data_validators/data_validator'
require 'data_validators/data_compute'
require 'errors'

module DataValidators
  class LogstashDataValidator
    include InputValidator
    include Errors
    include DataCompute
    include DataValidatorHelper

    attr_reader :log

    def initialize(log = Logger.new(STDOUT))
      @log = log
    end

    def validate_data(data = nil)
      unless data
        fail Errors::ValidationError, 'Skipping a malformed record. '\
          'No data available to validate'
      end

      valid_data = data.clone
      valid_data['timestamp'] = Time.now

      valid_data
    end
  end
end