# This module expects module DataValidatorHelper to be included with him
module DataValidators
  module DataCompute
    # Sums RSTIME (time when virtual machine was actually running)
    #
    # @param [Array] history records
    # @param [Boolean] completed whether vm was completed or not
    # @param [Fixnum] vm_id vm's id
    #
    # @return [Integer] sum of time when virtual machine was actually running
    def sum_rstime(history_records, completed, vm_id)
      return nil unless history_records

      rstime = 0

      history_records.each do |record|
        next unless default(record['rstart_time'], :nzn, nil) && default(record['rend_time'], :number, nil)
        rstart_time = record['rstart_time'].to_i
        rend_time = record['rend_time'].to_i

        if (rend_time > 0 && rstart_time > rend_time) || (rend_time == 0 && completed)
          fail Errors::ValidationError, 'Skipping a malformed record. '\
            "History records' times are invalid for vm with id #{vm_id}."
        end

        rend_time = rend_time == 0 ? Time.now.to_i : rend_time

        rstime += rend_time - rstart_time
      end

      rstime
    end

    # Sums disk size of all disks within the virtual machine
    #
    # @param [Array] disk records
    #
    # @return [Integer] sum of disk sizes in GB rounded up
    def sum_disk_size(disks, vm_id)
      return nil unless disks

      disk_size = 0

      disks.each do |disk|
        size = default(disk['size'], :number, nil)
        unless size
          log.warn("Disk size invalid for vm with id #{vm_id}")
          return nil
        end

        disk_size = disk_size + size.to_i
      end

      disk_size
    end
  end
end
