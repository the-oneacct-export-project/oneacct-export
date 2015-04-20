require 'data_validators/data_validator'
require 'data_validators/data_compute'
require 'data_validators/data_validator_helper'
require 'errors'

module DataValidators
  # Data validator class for apel output type
  class ApelDataValidator < DataValidator
    include InputValidator
    include Errors
    include DataCompute
    include DataValidatorHelper

    B_IN_GB = 1_073_741_824
    STATES = %w(started started suspended started suspended suspended completed completed suspended)
    DEFAULT_VALUE = 'NULL'

    attr_reader :log

    def initialize(log = Logger.new(STDOUT))
      @log = log
    end

    # All possible output fields and their default values:
    #
    # valid_data['endpoint'] - required
    # valid_data['site_name'] - required
    # valid_data['cloud_type'] - required
    # valid_data['vm_uuid'] - required
    # valid_data['start_time'] - required
    # valid_data['end_time'] - defaults to NULL, has to be bigger than valid_data['start_time'] if number
    # valid_data['machine_name'] - defaults to "one-#{valid_data['vm_uuid']}"
    # valid_data['user_id'] - defaults to NULL
    # valid_data['group_id'] - defaults to NULL
    # valid_data['user_dn'] - defaults to NULL
    # valid_data['group_name'] - defaults to nil
    # valid_data['status'] - defaults to NULL
    # valid_data['duration'] - required
    # valid_data['suspend'] - defaults to NULL
    # valid_data['cpu_count'] - defaults to 1
    # valid_data['network_inbound'] - defaults to 0
    # valid_data['network_outbound'] - defaults to 0
    # valid_data['memory'] - defaults to 0
    # valid_data['image_name'] - defaults to NULL
    # valid_data['disk_size']  -defaults to NULL
    def validate_data(data = nil)
      unless data
        fail Errors::ValidationError, 'Skipping a malformed record. '\
          'No data available to validate'
      end

      valid_data = data.clone

      fail_validation 'Endpoint' unless string?(data['endpoint'])
      fail_validation 'SiteName' unless string?(data['site_name'])
      fail_validation 'CloudType' unless string?(data['cloud_type'])
      fail_validation 'VMUUID' unless string?(data['vm_uuid'])

      fail_validation 'StartTime' unless non_zero_number?(data['start_time'])
      start_time = data['start_time'].to_i
      valid_data['start_time'] = Time.at(start_time)
      fail_validation 'EndTime' unless number?(data['end_time'])
      end_time = data['end_time'].to_i
      valid_data['end_time'] = end_time == 0 ? 'NULL' : Time.at(end_time)
      fail_validation 'EndTime' if end_time != 0 && valid_data['start_time'] > valid_data['end_time']

      valid_data['machine_name'] = default(data['machine_name'], :string, "one-#{valid_data['vm_uuid']}")
      valid_data['user_id'] = default(data['user_id'], :string, DEFAULT_VALUE)
      valid_data['group_id'] = default(data['group_id'], :string, DEFAULT_VALUE)
      valid_data['user_dn'] = default(data['user_dn'], :string, DEFAULT_VALUE)
      valid_data['user_name'] = default(data['user_name'], :string, DEFAULT_VALUE)
      valid_data['group_name'] = default(data['group_name'], :string, nil)

      status = default(data['status_code'], :number, nil)
      if status
        status = status.to_i
        fail_validation 'Status' unless status.to_s == data['status_code'] && status < STATES.size && status >= 0
      end
      valid_data['status'] = status ? STATES[status] : 'NULL'

      fail_validation 'HISTORY_RECORDS' if (!data['history']) || data['history'].empty?

      duration = sum_rstime(data['history'], valid_data['status'] == 'completed', valid_data['vm_uuid'])
      valid_data['duration'] = Time.at(duration)
      valid_data['suspend'] = end_time == 0 ? 'NULL' : (end_time - start_time) - duration
      valid_data['cpu_count'] = default(data['cpu_count'], :nzn, '1')

      valid_data['network_inbound'] = (default(data['network_inbound'], :number, 0).to_i / B_IN_GB).round
      valid_data['network_outbound'] = (default(data['network_outbound'], :number, 0).to_i / B_IN_GB).round

      valid_data['memory'] = default(data['memory'], :number, '0')
      valid_data['image_name'] = default(data['image_name'], :string, DEFAULT_VALUE)
      disk_size_sum = sum_disk_size(data['disks'], valid_data['vm_uuid'])
      valid_data['disk_size'] = disk_size_sum ? disk_size_sum : 'NULL'

      valid_data
    end
  end
end
