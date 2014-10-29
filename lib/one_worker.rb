file_dir_name = File.dirname(__FILE__)
$LOAD_PATH.unshift(file_dir_name) unless $LOAD_PATH.include?(file_dir_name)

require 'sidekiq'
require 'one_data_accessor'
require 'one_writer'
require 'sidekiq_conf'
require 'oneacct_exporter/log'
require 'settings'

class OneWorker
  include Sidekiq::Worker

  sidekiq_options retry: 5, dead: false,\
    queue: (Settings['sidekiq'] && Settings.sidekiq['queue']) ? Settings.sidekiq['queue'].to_sym : :default

  B_IN_GB = 1_073_741_824

  STRING = /[[:print:]]+/
  NUMBER = /[[:digit:]]+/
  NON_ZERO = /[1-9][[:digit:]]*/
  STATES = %w(started started suspended started suspended suspended completed completed suspended)

  def common_data
    common_data = {}
    common_data['endpoint'] = Settings['endpoint']
    common_data['site_name'] = Settings['site_name']
    common_data['cloud_type'] = Settings['cloud_type']

    common_data
  end

  def create_user_map(oda)
    logger.debug('Creating user map.')
    create_map(OpenNebula::UserPool, 'TEMPLATE/X509_DN', oda)
  end

  def create_image_map(oda)
    logger.debug('Creating image map.')
    create_map(OpenNebula::ImagePool, 'TEMPLATE/VMCATCHER_EVENT_AD_MPURI', oda)
  end

  def create_map(pool_type, mapping, oda)
    oda.mapping(pool_type, mapping)
  rescue => e
    msg = "Couldn't create map: #{e.message}. "\
      'Stopping to avoid malformed records.'
      logger.error(msg)
      raise msg
  end

  def load_vm(vm_id, oda)
    oda.vm(vm_id)
  rescue => e
    logger.error("Couldn't retrieve data for vm with id: #{vm_id}. #{e.message}. Skipping.")
    return nil
  end

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
    data['user_name'] = parse(vm['USER_TEMPLATE/USER_X509_DN'], STRING, nil)
    data['user_name'] = parse(user_map[data['user_id']], STRING) unless data['user_name']
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

    data['duration'] = parse(rstime.to_s, NON_ZERO)

    suspend = (end_time - start_time) - data['duration'].to_i unless end_time == 0
    data['suspend'] = parse(suspend.to_s, NUMBER)

    vcpu = vm['TEMPLATE/VCPU']
    data['cpu_count'] = parse(vcpu, NON_ZERO, '1')

    net_tx = parse(vm['NET_TX'], NUMBER, 0)
    data['network_inbound'] = (net_tx.to_i / B_IN_GB).round
    net_rx = parse(vm['NET_RX'], NUMBER, 0)
    data['network_outbound'] = (net_rx.to_i / B_IN_GB).round

    data['memory'] = parse(vm['MEMORY'], NUMBER, '0')

    data['image_name'] = parse(image_map[vm['TEMPLATE/DISK[1]/IMAGE_ID']], STRING, nil)
    data['image_name'] = parse(mixin(vm), STRING) unless data['image_name']

    data
  end

  def mixin(vm)
    mixin_locations = []
    mixin_locations << 'USER_TEMPLATE/OCCI_COMPUTE_MIXINS' << 'USER_TEMPLATE/OCCI_MIXIN' << 'TEMPLATE/OCCI_MIXIN'

    mixin_locations.each do |mixins|
      vm.each mixins do |mixin|
        mixin = mixin.text.split
        mixin.select! { |line| line.include? 'os_tpl' }
        return mixin[0] unless mixins.empty?
      end
    end

    nil
  end

  def sum_rstime(vm)
    rstime = 0
    vm.each 'HISTORY_RECORDS/HISTORY' do |h|
      next unless h['RSTIME'] && h['RETIME'] && h['RETIME'] != '0' && h['RSTIME'] != '0'
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

  def perform(vms, output)
    OneacctExporter::Log.setup_log_level(logger)

    vms = vms.split('|')

    oda = OneDataAccessor.new(logger)
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

    write_data(data, output)
  end

  def write_data(data, output)
    logger.debug('Creating writer...')
    ow = OneWriter.new(data, output, logger)
    ow.write
  rescue => e
    msg = "Canno't write result to #{output}: #{e.message}"
    logger.error(msg)
    raise msg
  end

  def parse(value, regex, substitute = 'NULL')
    regex =~ value ? value : substitute
  end
end
