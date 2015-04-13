module DataValidators
  # Interface class for data validator implementations
  class DataValidator
    # Validates data for specific output formate and sets default values if necessary.
    #
    # @param data [Hash] data to be validated
    # @return [Hash] data with default values set if necessary
    def validate_data(data = nil)
      fail Errors::NotImplementedError, "#{__method__} is just a stub!"
    end
  end
end
