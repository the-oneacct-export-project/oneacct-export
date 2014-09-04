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

  def perform(vms, output)
    OneacctExporter::Log.setup_log_level(logger)

    common_data = {}
    common_data['endpoint'] = Settings['endpoint']
    common_data['site_name'] = Settings['site_name']
    common_data['cloud_type'] = Settings['cloud_type']

    vms = vms.split('|')

    begin
      oda = OneDataAccessor.new(logger)
      logger.debug('Creating user and image maps.')
      user_map = oda.mapping(OpenNebula::UserPool, 'TEMPLATE/X509_DN')
      logger.debug("user_map: #{user_map}")
      image_map = oda.mapping(OpenNebula::ImagePool, 'NAME')
      logger.debug("image_map: #{image_map}")
    rescue => e
      msg = "Couldn't create user or image map: #{e.message}. "\
            'Stopping to avoid malformed records.'
      logger.error(msg)
      raise msg
    end

    states = []
    states << 'started' << 'started' << 'suspended' << 'started' << 'suspended'
    states << 'suspended' << 'completed' << 'completed' << 'suspended'

    full_data = []

    vms.each do |vm_id|
      begin
        logger.debug("Processing vm with id: #{vm_id}")
        vm = oda.vm(vm_id)
      rescue => e
        @log.error("Couldn't retrieve data for vm with id: #{vm_id}. Skipping.")
        next
      end

      data = common_data.clone

      data['vm_uuid'] = parse(vm['ID'], STRING)

      unless vm['STIME']
        logger.error('Skipping a malformed record. '\
                     "VM with id #{data['vm_uuid']} has no StartTime.")
        next
      end
      data['start_time'] = parse(vm['STIME'], NUMBER)
      start_time = data['start_time'].to_i
      data['start_time_readable'] = parse(Time.at(start_time).strftime('%F %T%:z'), STRING)

      data['machine_name'] = parse(vm['DEPLOY_ID'], STRING, "one-#{data['vm_uuid']}")
      data['user_id'] = parse(vm['UID'], STRING)
      data['group_id'] = parse(vm['GID'], STRING)
      data['user_name'] = parse(user_map[data['user_id']], STRING)
      data['fqan'] = parse(vm['GNAME'], STRING, nil)
      data['status'] = parse(states[vm['STATE'].to_i], STRING)
      data['end_time'] = parse(vm['ETIME'], NON_ZERO)
      end_time = data['end_time'].to_i

      if end_time != 0 && start_time > end_time
        logger.error('Skipping malformed record. '\
                     "VM with id #{data['vm_uuid']} has wrong time entries.")
        next
      end

      unless vm['HISTORY_RECORDS/HISTORY[1]']
        logger.warn('Skipping malformed record. '\
                    "VM with id #{data['vm_uuid']} has no history records.")
        next
      end

      rstime = sum_rstime(vm)
      next unless rstime

      data['duration'] = parse(rstime.to_s, NON_ZERO)

      suspend = (end_time - start_time) - data['duration'].to_i unless end_time == 0
      data['suspend'] = parse(suspend.to_s, NUMBER)

      vcpu = vm['TEMPLATE/VCPU']
      data['cpu_count'] = parse(vcpu, NON_ZERO, 1)

      net_tx = parse(vm['NET_TX'], NUMBER, 0)
      data['network_inbound'] = (net_tx.to_i / B_IN_GB).round
      net_rx = parse(vm['NET_RX'], NUMBER, 0)
      data['network_outbound'] = (net_rx.to_i / B_IN_GB).round

      data['memory'] = parse(vm['MEMORY'], NUMBER, 0)
      data['image_name'] = parse(image_map[vm['TEMPLATE/DISK[1]/IMAGE_ID']], STRING)

      logger.debug("Adding vm with data: #{data} for export.")
      full_data << data
    end

    begin
      logger.debug('Creating writer...')
      ow = OneWriter.new(full_data, output, logger)
      ow.write
    rescue => e
      msg = "Canno't write result to #{output}: #{e.message}"
      logger.error(msg)
      raise msg
    end
  end

  def sum_rstime(vm)
    rstime = 0
    vm.each 'HISTORY_RECORDS/HISTORY' do |h|
      next unless h['RSTIME'] && h['RETIME'] && h['RETIME'] != '0' && h['RSTIME'] != '0'
      if h['RSTIME'].to_i > h['RETIME'].to_i
        logger.warn('Skipping malformed record. '\
                    "VM with id #{data['vm_uuid']} has wrong CpuDuration.")
        rstime = nil
        break
      end
      rstime += h['RETIME'].to_i - h['RSTIME'].to_i
    end

    rstime
  end

  def parse(value, regex, substitute = 'NULL')
    regex =~ value ? value : substitute
  end
end
