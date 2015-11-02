# This module expects modules Errors and InputValidator to be included with him
module DataValidators
  module DataValidatorHelper
    def fail_validation(field)
      fail Errors::ValidationError, 'Skipping a malformed record. '\
        "Field '#{field}' is invalid."
    end

    def default(value, condition_method, default_value)
      return string?(value) ? value : default_value if condition_method == :string
      return number?(value) ? value : default_value if condition_method == :number
      return decimal?(value) ? value : default_value if condition_method == :decimal
      return non_zero_number?(value) ? value : default_value if condition_method == :nzn
    end
  end
end
