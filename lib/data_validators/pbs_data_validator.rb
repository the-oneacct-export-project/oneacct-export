require 'data_validators/data_validator'
require 'data_validators/data_compute'
require 'errors'

module DataValidators

  # Data validator class for pbs output type
  class PbsDataValidator < DataValidator
    include InputValidator
    include Errors
    include DataCompute
    include DataValidatorHelper

    COMPLETED = '6'

    attr_reader :log

    def initialize(log = Logger.new(STDOUT))
      @log = log
    end

    # All possible output feilds and their default values:
    #
    # valid_data['host'] - required
    # valid_data['pbs_queue'] - required
    # valid_data['realm'] - required
    # valid_data['scratch_type'] - optional, defaults to nil
    # valid_data['vm_uuid'] - required
    # valid_data['machine_name'] - required, defaults to "one-#{valid_data['vm_uuid']}"
    # valid_data['user_name'] - required
    # valid_data['group_name'] - required
    # valid_data['duration'] - required, defaults to 00:00:00
    # valid_data['cpu_count'] - required
    # valid_data['memory'] - required
    # valid_data['disk_size']  - optional, defaults to nil
    # valid_data['history'] - set of history records
    # history_record['start_time'] - required
    # history_record['end_time'] - required
    # history_record['state'] - required, either all history records 'U' or last history record with 'E' if vm finished
    # history_record['seq'] - required
    # history_record['hostname'] - required
    def validate_data(data=nil)
      unless data
        fail Errors::ValidationError, 'Skipping a malformed record. '\
          'No data available to validate'
      end

      valid_data = data.clone

      fail_validation 'host' unless is_string?(data['host'])
      fail_validation 'queue' unless is_string?(data['pbs_queue'])
      fail_validation 'owner' unless is_string?(data['realm'])
      fail_validation 'VMUUID' unless is_string?(data['vm_uuid'])
      fail_validation 'owner' unless is_string?(data['user_name'])
      fail_validation 'group' unless is_string?(data['group_name'])
      fail_validation 'ppn' unless is_number?(data['cpu_count'])
      fail_validation 'mem' unless is_number?(data['memory'])
      fail_validation 'HISTORY_RECORDS' if !data['history'] || data['history'].empty?

      history = []
      data['history'].each do |h|
        history_record = h.clone
        fail_validation 'start' unless is_non_zero_number?(h['start_time'])
        history_record['start_time'] = Time.at(h['start_time'].to_i)
        fail_validation 'end' unless is_number?(h['end_time'])
        history_record['end_time'] = Time.at(h['end_time'].to_i)
        fail_validation 'seq' unless is_number?(h['seq'])
        fail_validation 'hostname' unless is_string?(h['hostname'])

        history_record['state'] = 'U'
        history << history_record
      end

      history.last['state'] = 'E' if data['status'] == COMPLETED
      valid_data['history'] = history

      valid_data['machine_name'] = default(data['machine_name'], :string, "one-#{valid_data['vm_uuid']}")

      duration = sum_rstime(data['history'], valid_data['vm_uuid'])
      valid_data['duration'] = Time.at(duration)

      valid_data['disk_size'] = sum_disk_size(data['disks'], valid_data['vm_uuid'])

      valid_data
    end
  end
end
