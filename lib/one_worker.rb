file_dir_name = File.dirname(__FILE__)
$LOAD_PATH.unshift(file_dir_name) unless $LOAD_PATH.include?(file_dir_name)

require 'sidekiq'
require 'one_data_accessor'
require 'one_writer'
require 'sidekiq_conf'
require 'oneacct_exporter/log'
require 'oneacct_exporter/version'
require 'settings'
require 'data_validators/apel_data_validator'
require 'data_validators/pbs_data_validator'
require 'data_validators/logstash_data_validator'
require 'output_types'
require 'errors'
require 'ipaddr'

# Sidekiq worker class
class OneWorker
  include Sidekiq::Worker
  include OutputTypes
  include Errors

  sidekiq_options retry: 5, dead: false, \
                  queue: (Settings['sidekiq'] && Settings.sidekiq['queue']) ? Settings.sidekiq['queue'].to_sym : :default

  IGNORED_NETWORKS=["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16"].map {|x| IPAddr.new x}

  # Prepare data that are common for all the output types
  def common_data
    data = {}
    data['oneacct_export_version'] = ::OneacctExporter::VERSION

    data
  end

  # Prepare data that are specific for output type and common for every virtual machine
  def output_type_specific_data
    data = {}
    if PBS_OT.include?(Settings.output['output_type']) && Settings.output['pbs']
      data['realm'] = Settings.output.pbs['realm']
      data['pbs_queue'] = Settings.output.pbs['queue']
      data['scratch_type'] = Settings.output.pbs['scratch_type']
      data['host'] = Settings.output.pbs['host_identifier']
    end

    if APEL_OT.include?(Settings.output['output_type'])
      data['endpoint'] = Settings.output.apel['endpoint'].chomp('/')
      data['site_name'] = Settings.output.apel['site_name']
      data['cloud_type'] = Settings.output.apel['cloud_type']
      data['cloud_compute_service'] = Settings.output.apel['cloud_compute_service']
    end

    if LOGSTASH_OT.include?(Settings.output['output_type'])
      data['host'] = Settings.output.logstash['host']
      data['port'] = Settings.output.logstash['port']
    end

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

  def create_cluster_map(oda)
    logger.debug('Creating cluster map.')
    create_map(OpenNebula::ClusterPool, 'TEMPLATE/APEL_SITE_NAME', oda)
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
  def process_vm(vm, user_map, image_map, cluster_map, benchmark_map)
    data = common_data
    data.merge! output_type_specific_data

    data['vm_uuid'] = vm['ID']
    data['start_time'] = vm['STIME']
    data['end_time'] = vm['ETIME']
    data['machine_name'] = vm['DEPLOY_ID']
    data['user_id'] = vm['UID']
    data['group_id'] = vm['GID']
    data['user_dn'] = vm['USER_TEMPLATE/USER_X509_DN']
    data['user_dn'] ||= user_map[data['user_id']]
    data['user_name'] = vm['UNAME']
    data['group_name'] = vm['GNAME']
    data['status_code'] = vm['STATE']
    data['status'] = vm.state_str
    data['cpu_count'] = vm['TEMPLATE/VCPU']
    data['network_inbound'] = vm['NET_TX']
    data['network_outbound'] = vm['NET_RX']
    data['memory'] = vm['TEMPLATE/MEMORY']
    data['image_name'] = vm['TEMPLATE/DISK[1]/VMCATCHER_EVENT_AD_MPURI']
    data['image_name'] ||= image_map[vm['TEMPLATE/DISK[1]/IMAGE_ID']]
    data['image_name'] ||= mixin(vm)
    data['image_name'] ||= vm['TEMPLATE/DISK[1]/IMAGE_ID']
    data['history'] = history_records(vm)
    data['disks'] = disk_records(vm)
    data['number_of_public_ips'] = number_of_public_ips(vm)

    benchmark = search_benchmark(vm, benchmark_map)
    data['benchmark_type'] = benchmark[:benchmark_type]
    data['benchmark_value'] = benchmark[:benchmark_value]

    site_name = cluster_map[vm['HISTORY_RECORDS/HISTORY[1]/CID']]
    data['site_name'] = site_name if site_name

    data
  end

  # Returns an array of history records from vm
  #
  # @param [OpenNebula::VirtualMachine] vm virtual machine
  #
  # @return [Array] array of hashes representing vm's history records
  def history_records(vm)
    history = []
    vm.each 'HISTORY_RECORDS/HISTORY' do |h|
      history_record = {}
      history_record['start_time'] = h['STIME']
      history_record['end_time'] = h['ETIME']
      history_record['rstart_time'] = h['RSTIME']
      history_record['rend_time'] = h['RETIME']
      history_record['seq'] = h['SEQ']
      history_record['hostname'] = h['HOSTNAME']

      history << history_record
    end

    history
  end

  # Returns an array of disk records from vm
  #
  # @param [OpenNebula::VirtualMachine] vm virtual machine
  #
  # @return [Array] array of hashes representing vm's disk records
  def disk_records(vm)
    disks = []
    vm.each 'TEMPLATE/DISK' do |d|
      disk = {}
      disk['size'] = d['SIZE']

      disks << disk
    end

    disks
  end

  # Returns number of unique public ip addresses of vm
  #
  # @param [OpenNebula::VirtualMachine] vm virtual machine
  #
  # @return [Integer] number of unique public ip addresses represented by integer
  def number_of_public_ips(vm)
    all_ips = []
    vm.each 'TEMPLATE/NIC' do |nic|
      nic.each 'IP' do |ip|
        all_ips << ip.text if ip_public?(ip)
      end
    end

    all_ips.uniq.length
  end

  # Look for 'os_tpl' OCCI mixin to better identify virtual machine's image
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

  # Sidekiq specific method, specifies the purpose of the worker
  #
  # @param [String] vms IDs of virtual machines to process in form of numbers separated by '|'
  # (easier for cooperation with redis)
  # @param [String] file_number number of the output file
  def perform(vms, file_number)
    OneacctExporter::Log.setup_log_level(logger)

    vms = vms.split('|')

    oda = OneDataAccessor.new(false, logger)
    user_map = create_user_map(oda)
    image_map = create_image_map(oda)
    cluster_map = create_cluster_map(oda)
    benchmark_map = oda.benchmark_map

    data = []

    vms.each do |vm_id|
      vm = load_vm(vm_id, oda)
      next unless vm

      begin
        logger.debug("Processing vm with id: #{vm_id}.")
        vm_data = process_vm(vm, user_map, image_map, cluster_map, benchmark_map)

        validator = DataValidators::ApelDataValidator.new(logger) if APEL_OT.include?(Settings.output['output_type'])
        validator = DataValidators::PbsDataValidator.new(logger) if PBS_OT.include?(Settings.output['output_type'])
        validator = DataValidators::LogstashDataValidator.new(logger) if LOGSTASH_OT.include?(Settings.output['output_type'])

        vm_data = validator.validate_data(vm_data) if validator
      rescue Errors::ValidationError => e
        logger.error("Error occured during processing of vm with id: #{vm_id}. #{e.message}")
        next
      end

      logger.debug("Adding vm with data: #{vm_data} for export.")
      data << vm_data
    end

    write_data(data, file_number) unless data.empty?
  end

  # Write processed data into output directory
  #
  # @param [Hash] data data to be written into file
  # @param [Fixnum] file_number sequence number of file data will be written to
  def write_data(data, file_number)
    logger.debug('Creating writer...')
    ow = OneWriter.new(data, file_number, logger)
    ow.write
  rescue => e
    msg = "Cannot write result: #{e.message}"
    logger.error(msg)
    raise msg
  end

  # Search benchmark type and value virtual machine.
  #
  # @param [OpenNebula::VirtualMachine] vm virtual machine
  # @param [Hash] benchmark_map map of all hosts' benchmarks
  #
  # @return [Hash] benchmark type and value or both can be nil
  def search_benchmark(vm, benchmark_map)
    nil_benchmark = { :benchmark_type => nil, :benchmark_value => nil }
    map = benchmark_map[vm['HISTORY_RECORDS/HISTORY[last()]/HID']]
    return nil_benchmark unless map
    return nil_benchmark unless vm['USER_TEMPLATE/OCCI_COMPUTE_MIXINS']

    occi_compute_mixins = vm['USER_TEMPLATE/OCCI_COMPUTE_MIXINS'].split(/\s+/)
    occi_compute_mixins.each do |mixin|
      return { :benchmark_type => map[:benchmark_type], :benchmark_value => map[:mixins][mixin] } if map[:mixins].has_key?(mixin)
    end
    nil_benchmark
  end

  private

  # Check if IP is public
  #
  # @param [String] ip address
  #
  # @return [Bool] true or false
  def ip_public?(ip)
    ip_obj = IPAddr.new(ip.text)
    IGNORED_NETWORKS.each do |net|
      return false if net.include? ip_obj
    end
    true
  end
end
