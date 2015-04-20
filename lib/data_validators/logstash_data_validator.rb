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

      fail_validation 'start_time' unless non_zero_number?(data['start_time'])
      valid_data['start_time'] = data['start_time'].to_i
      fail_validation 'end_time' unless number?(data['end_time'])
      valid_data['end_time'] = data['end_time'].to_i
      fail_validation 'end_time' if valid_data['end_time'] != 0 && valid_data['start_time'] > valid_data['end_time']

      fail_validation 'user_id' unless number?(data['user_id'])
      valid_data['user_id'] = data['user_id'].to_i
      fail_validation 'group_id' unless number?(data['group_id'])
      valid_data['group_id'] = data['group_id'].to_i

      fail_validation 'status_code' unless number?(data['status_code'])
      valid_data['status_code'] = data['status_code'].to_i

      fail_validation 'cpu_count' unless number?(data['cpu_count'])
      valid_data['cpu_count'] = data['cpu_count'].to_i
      fail_validation 'network_inbound' unless number?(data['network_inbound'])
      valid_data['network_inbound'] = data['network_inbound'].to_i
      fail_validation 'network_outbound' unless number?(data['network_outbound'])
      valid_data['network_outbound'] = data['network_outbound'].to_i
      fail_validation 'memory' unless number?(data['memory'])
      valid_data['memory'] = data['memory'].to_i

      fail_validation 'history' unless data['history']
      history = []
      data['history'].each do |h|
        history_record = h.clone
        fail_validation 'history record start_time' unless non_zero_number?(h['start_time'])
        history_record['start_time'] = h['start_time'].to_i
        fail_validation 'history record end_time' unless number?(h['end_time'])
        history_record['end_time'] = h['end_time'].to_i
        fail_validation 'history record rstart_time' unless non_zero_number?(h['rstart_time'])
        history_record['rstart_time'] = h['rstart_time'].to_i
        fail_validation 'history record rend_time' unless number?(h['rend_time'])
        history_record['rend_time'] = h['rend_time'].to_i
        fail_validation 'history record seq' unless number?(h['seq'])
        history_record['seq'] = h['seq'].to_i

        history << history_record
      end
      valid_data['history'] = history

      fail_validation 'disks' unless data['disks']
      disks = []
      data['disks'].each do |d|
        disk = d.clone
        disk['size'] = d['size']
        disk['size'] = d['size'].to_i if number?(d['size'])

        disks << disk
      end
      valid_data['disks'] = disks

      valid_data
    end
  end
end
