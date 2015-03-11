file_dir_name = File.dirname(__FILE__)
$LOAD_PATH.unshift(file_dir_name) unless $LOAD_PATH.include?(file_dir_name)

require 'sidekiq'
require 'one_data_accessor'
require 'one_writer'
require 'sidekiq_conf'
require 'oneacct_exporter/log'
require 'settings'

# Sidekiq worker class
class OneWorker
  include Sidekiq::Worker

  sidekiq_options retry: 5, dead: false,\
    queue: (Settings['sidekiq'] && Settings.sidekiq['queue']) ? Settings.sidekiq['queue'].to_sym : :default

  B_IN_GB = 1_073_741_824

  STRING = /[[:print:]]+/
  NUMBER = /[[:digit:]]+/
  NON_ZERO = /[1-9][[:digit:]]*/

  STATES = %w(started started suspended started suspended suspended completed completed suspended)

  PBS_OT = 'pbs-0.1'

  # Prepare data that are common for every virtual machine
  def common_data
    common_data = {}
    common_data['endpoint'] = Settings['endpoint'].chomp('/')
    common_data['site_name'] = Settings['site_name']
    common_data['cloud_type'] = Settings['cloud_type']
    common_data.merge!(output_type_specific_data)

    common_data
  end

  def output_type_specific_data
    data = {}
    if Settings.output['output_type'] == PBS_OT && Settings.output['pbs']
      data['realm'] = Settings.output.pbs['realm']
      data['pbs_queue'] = Settings.output.pbs['queue']
      data['scratch_type'] = Settings.output.pbs['scratch_type']
      data['host'] = Settings.output.pbs['host_identifier']
    end

    data['realm'] = 'META' unless data['realm']
    data['pbs_queue'] = 'cloud' unless data['pbs_queue']
    data['scratch_type'] = 'local' unless data['pbs_scratch_type']
    data['host'] = 'on_localhost' unless data['host']

    data
  end

  # Create mapping of user ID and specified element
  #
  # @return [Hash] created map
  def create_user_map(oda)
    logger.debug('Creating user map.')
    create_map(OpenNebula::UserPool, 'TEMPLATE/X509_DN', oda)
  end

  # Create mapping of image ID and specified element
  #
  # @return [Hash] created map
  def create_image_map(oda)
    logger.debug('Creating image map.')
    create_map(OpenNebula::ImagePool, 'TEMPLATE/VMCATCHER_EVENT_AD_MPURI', oda)
  end

  # Generic method for mapping creation
  def create_map(pool_type, mapping, oda)
    oda.mapping(pool_type, mapping)
  rescue => e
    msg = "Couldn't create map: #{e.message}. "\
      'Stopping to avoid malformed records.'
      logger.error(msg)
      raise msg
  end

  # Load virtual machine with specified ID
  #
  # @return [OpenNebula::VirtualMachine] virtual machine
  def load_vm(vm_id, oda)
    oda.vm(vm_id)
  rescue => e
    logger.error("Couldn't retrieve data for vm with id: #{vm_id}. #{e.message}. Skipping.")
    return nil
  end

  # Obtain and parse required data from vm 
  #
  # @return [Hash] required data from virtual machine
  def process_vm(vm, user_map, image_map)
    data = common_data.clone

    data['vm_uuid'] = parse(vm['ID'], STRING)
    unless vm['STIME']
      logger.error('Skipping a malformed record. '\
                   "VM with id #{data['vm_uuid']} has no StartTime.")
      return nil
    end

    data['start_time'] = Time.at(parse(vm['STIME'], NUMBER).to_i)
    start_time = data['start_time'].to_i
    if start_time == 0
      logger.error('Skipping a malformed record. '\
                   "VM with id #{data['vm_uuid']} has malformed StartTime.")
      return nil
    end
    data['end_time'] = parse(vm['ETIME'], NON_ZERO)
    end_time = data['end_time'].to_i
    data['end_time'] = Time.at(end_time) if end_time != 0

    if end_time != 0 && start_time > end_time
      logger.error('Skipping malformed record. '\
                   "VM with id #{data['vm_uuid']} has wrong time entries.")
      return nil
    end

    data['machine_name'] = parse(vm['DEPLOY_ID'], STRING, "one-#{data['vm_uuid']}")
    data['user_id'] = parse(vm['UID'], STRING)
    data['group_id'] = parse(vm['GID'], STRING)
    data['user_dn'] = parse(vm['USER_TEMPLATE/USER_X509_DN'], STRING, nil)
    data['user_dn'] = parse(user_map[data['user_id']], STRING) unless data['user_name']
    data['user_name'] = parse(vm['UNAME'], STRING)
    data['group_name'] = parse(vm['GNAME'], STRING)
    data['fqan'] = parse(vm['GNAME'], STRING, nil)

    if vm['STATE']
      data['status'] = parse(STATES[vm['STATE'].to_i], STRING)
    else
      data['status'] = 'NULL'
    end

    unless vm['HISTORY_RECORDS/HISTORY[1]']
      logger.warn('Skipping malformed record. '\
                  "VM with id #{data['vm_uuid']} has no history records.")
      return nil
    end

    rstime = sum_rstime(vm)
    return nil unless rstime

    data['duration'] = Time.at(parse(rstime.to_s, NON_ZERO).to_i)

    suspend = (end_time - start_time) - data['duration'].to_i unless end_time == 0
    data['suspend'] = parse(suspend.to_s, NUMBER)

    data['cpu_count'] = parse(vm['TEMPLATE/VCPU'], NON_ZERO, '1')

    net_tx = parse(vm['NET_TX'], NUMBER, 0)
    data['network_inbound'] = (net_tx.to_i / B_IN_GB).round
    net_rx = parse(vm['NET_RX'], NUMBER, 0)
    data['network_outbound'] = (net_rx.to_i / B_IN_GB).round

    data['memory'] = parse(vm['TEMPLATE/MEMORY'], NUMBER, '0')

    data['image_name'] = parse(vm['TEMPLATE/DISK[1]/VMCATCHER_EVENT_AD_MPURI'], STRING, nil)
    data['image_name'] = parse(image_map[vm['TEMPLATE/DISK[1]/IMAGE_ID']], STRING, nil) unless data['image_name']
    data['image_name'] = parse(mixin(vm), STRING, nil) unless data['image_name']
    data['image_name'] = parse(vm['TEMPLATE/DISK[1]/IMAGE_ID'], STRING) unless data['image_name']

    data['disk_size'] = sum_disk_size(vm)

    history = history_records(vm)
    history.last['state'] = 'E' if data['status'] == 'completed'
    data['history'] = history

    data
  end

  def history_records(vm)
    history = []
    vm.each 'HISTORY_RECORDS/HISTORY' do |h|
      history_record = {}
      history_record['start_time'] = Time.at(parse(h['STIME'], NUMBER, 0).to_i)
      history_record['end_time'] = Time.at(parse(h['ETIME'], NUMBER, 0).to_i)
      history_record['seq'] = parse(h['SEQ'], NUMBER, nil)
      unless history_record['seq']
        logger.error('Skipping a malformed record. '\
                     "VM with id #{vm['ID']} has history record with invalid sequence number.")
        return nil
      end
      history_record['hostname'] = parse(h['HOSTNAME'], STRING)
      history_record['state'] = 'U'

      history << history_record
    end

    history
  end

  # Look for 'os_tpl' OCCI mixin to better identifie virtual machine's image
  #
  # @param [OpenNebula::VirtualMachine] vm virtual machine
  #
  # @return [NilClass, String] if found, mixin identifying string, nil otherwise
  def mixin(vm)
    mixin_locations = %w(USER_TEMPLATE/OCCI_COMPUTE_MIXINS USER_TEMPLATE/OCCI_MIXIN TEMPLATE/OCCI_MIXIN)

    mixin_locations.each do |mixin_location|
      vm.each mixin_location do |mixin|
        mixin = mixin.text.split
        mixin.select! { |line| line.include? '/occi/infrastructure/os_tpl#' }
        return mixin.first unless mixin.empty?
      end
    end

    nil # nothing found
  end

  # Sums RSTIME (time when virtual machine was actually running)
  #
  # @param [OpenNebula::VirtualMachine] vm virtual machine
  #
  # @return [Integer] RSTIME
  def sum_rstime(vm)
    rstime = 0
    vm.each 'HISTORY_RECORDS/HISTORY' do |h|
      next unless h['RSTIME'] && h['RETIME'] && h['RSTIME'] != '0'
      if h['RETIME'] == '0'
        rstime += Time.now.to_i - h['RSTIME'].to_i
        next
      end
      if h['RSTIME'].to_i > h['RETIME'].to_i
        logger.warn('Skipping malformed record. '\
                    "VM with id #{vm['ID']} has wrong CpuDuration.")
        rstime = nil
        break
      end
      rstime += h['RETIME'].to_i - h['RSTIME'].to_i
    end

    rstime
  end

  # Sums disk size of all disks within the virtual machine
  #
  # @param [OpenNebula::VirtualMachine] vm virtual machine
  #
  # @return [Integer] sum of disk sizes in GB rounded up
  def sum_disk_size(vm)
    disk_size = 'NULL'
    vm.each 'TEMPLATE/DISK' do |disk|
      return 'NULL' unless disk['SIZE']

      size = parse(disk['SIZE'], NUMBER, nil)
      unless size
        logger.warn("Disk size invalid for VM with id #{vm['ID']}.")
        return 'NULL'
      end
      disk_size = disk_size.to_i + size.to_i
    end

    disk_size
  end

  # Sidekiq specific method, specifies the purpose of the worker
  #
  # @param [String] vms IDs of virtual machines to process in form of numbers separated by '|' (easier for cooperation with redis)
  # @param [String] file_number number of the output file
  def perform(vms, file_number)
    OneacctExporter::Log.setup_log_level(logger)

    vms = vms.split('|')

    oda = OneDataAccessor.new(false, logger)
    user_map = create_user_map(oda)
    image_map = create_image_map(oda)

    data = []

    vms.each do |vm_id|
      vm = load_vm(vm_id, oda)
      next unless vm

      logger.debug("Processing vm with id: #{vm_id}.")
      vm_data = process_vm(vm, user_map, image_map)
      next unless vm_data

      logger.debug("Adding vm with data: #{vm_data} for export.")
      data << vm_data
    end

    write_data(data, file_number)
  end

  # Write processed data into output directory
  def write_data(data, file_number)
    logger.debug('Creating writer...')
    ow = OneWriter.new(data, file_number, logger)
    ow.write
  rescue => e
    msg = "Cannot write result: #{e.message}"
    logger.error(msg)
    raise msg
  end

  def parse(value, regex, substitute = 'NULL')
    regex =~ value ? value : substitute
  end
end
