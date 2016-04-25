require 'opennebula'
require 'settings'
require 'errors'
require 'logger'
require 'input_validator'

# Class for accessing OpenNebula via XML RPC and requesting accounting data
#
# @attr_reader [any logger] logger
# @attr_reader [Integer] batch_size number of vm records to request
# @attr_reader [OpenNebula::Client] client client for communicaton with OpenNebula
# @attr_reader [TrueClass, FalseClass] compatibility whether or not communicate in
# compatibility mode (omit some newer API functions)
class OneDataAccessor
  include Errors
  include InputValidator

  STATE_DONE = '6'

  attr_reader :log, :batch_size, :client, :compatibility
  attr_accessor :start_vm_id

  def initialize(compatibility, log = nil)
    @log = log ? log : Logger.new(STDOUT)
    @compatibility = compatibility

    @batch_size = Settings.output['num_of_vms_per_file'] ? Settings.output['num_of_vms_per_file'] : 500
    fail ArgumentError, 'Wrong number of vms per file.' unless number?(@batch_size)

    @compatibility_vm_pool = nil
    @start_vm_id = 0

    initialize_client
  end

  # Initialize OpenNebula client for further connection
  def initialize_client
    secret = Settings['xml_rpc'] ? Settings.xml_rpc['secret'] : nil
    endpoint = Settings['xml_rpc'] ? Settings.xml_rpc['endpoint'] : nil
    fail ArgumentError, "#{endpoint} is not a valid URL." if endpoint && !uri?(endpoint)

    @client = OpenNebula::Client.new(secret, endpoint)
  end

  # Create mapping from element's ID to its xpath value
  #
  # @param [one of OpenNebula pool classes] pool_class pool to read elements from
  # @param [String] xpath xpath pointing to value within the element
  #
  # @return [Hash] generated map
  def mapping(pool_class, xpath)
    @log.debug("Generating mapping for class: #{pool_class} and xpath: '#{xpath}'.")
    pool = pool_class.new(@client)
    # call info_all method instead of info on pools that support it
    if pool.respond_to? 'info_all'
      rc = pool.info_all
      check_retval(rc, Errors::ResourceRetrievalError)
    else
      rc = pool.info
      check_retval(rc, Errors::ResourceRetrievalError)
    end

    # generate mapping
    map = {}
    pool.each do |item|
      unless item['ID']
        @log.error("Skipping a resource of the type #{pool_class} without an ID present.")
        next
      end
      map[item['ID']] = item[xpath]
    end

    map
  end

  # Retrieve virtual machine
  #
  # @param [Integer] vm_id ID of vm to retrieve
  #
  # @return [OpenNebula::VirtualMachine] virtual machine
  def vm(vm_id)
    fail ArgumentError, "#{vm_id} is not a valid id." unless number?(vm_id)
    @log.debug("Retrieving virtual machine with id: #{vm_id}.")
    vm = OpenNebula::VirtualMachine.new(OpenNebula::VirtualMachine.build_xml(vm_id), @client)
    rc = vm.info
    check_retval(rc, Errors::ResourceRetrievalError)
    vm
  end

  # Retriev IDs of specified virtual machines
  #
  # @param [Hash] range date range into which virtual machine has to belong
  # @param [Hash] groups groups into one of which owner of the virtual machine has to belong
  #
  # @return [Array] array with virtual machines' IDs
  def vms(range, groups)
    vms = []
    # load specific batch
    vm_pool = load_vm_pool
    return nil if vm_pool.count == 0

    @log.debug("Searching for vms based on range: #{range} and groups: #{groups}.")
    vm_pool.each do |vm|
      unless vm['ID']
        @log.error('Skipping a record without an ID present.')
        next
      end

      # skip unsuitable virtual machines
      next unless want?(vm, range, groups)

      vms << vm['ID'].to_i
    end

    @log.debug("Selected vms: #{vms}.")
    vms
  end

  # Check whether obtained vm meets requierements
  #
  # @param [OpenNebula::VirtualMachine] vm virtual machine instance to check
  # @param [Hash] range date range into which virtual machine has to belong
  # @param [Hash] groups groups into one of which owner of the virtual machine has to belong
  #
  # @return [TrueClass, FalseClass] true if virtual machine meets requirements, false otherwise
  def want?(vm, range, groups)
    if vm.nil?
      @log.warn('Obtained nil vm from vm pool.')
      return false
    end
    # range restriction
    unless range.nil? || range.empty?
      return false if range[:from] && vm['STATE'] == STATE_DONE && vm['ETIME'].to_i < range[:from].to_i
      return false if range[:to] && vm['STIME'].to_i > range[:to].to_i
    end

    # groups restriction
    unless groups.nil? || groups.empty?
      return false if groups[:include] && !groups[:include].include?(vm['GNAME'])
      return false if groups[:exclude] && groups[:exclude].include?(vm['GNAME'])
    end

    true
  end

  # Load part of virtual machine pool
  #
  # @param [Integer] batch_number
  def load_vm_pool
    @log.debug("Loading vm pool from id: #{start_vm_id}.")
    from = @start_vm_id
    how_many = @batch_size
    to = from + how_many - 1

    # if in compatibility mode, whole virtual machine pool has to be loaded for the first time
    if @compatibility
      unless @compatibility_vm_pool
        vm_pool = OpenNebula::VirtualMachinePool.new(@client)
        rc = vm_pool.info(OpenNebula::Pool::INFO_ALL, -1, -1, OpenNebula::VirtualMachinePool::INFO_ALL_VM)
        check_retval(rc, Errors::ResourceRetrievalError)
        @compatibility_vm_pool = vm_pool.to_a
      end

      pool = @compatibility_vm_pool[from..to] || []
      @start_vm_id = pool.last.id + 1 unless pool.empty?

      return pool
    else
      vm_pool = OpenNebula::VirtualMachinePool.new(@client)
      rc = vm_pool.info(OpenNebula::Pool::INFO_ALL, from, -how_many, OpenNebula::VirtualMachinePool::INFO_ALL_VM)
      check_retval(rc, Errors::ResourceRetrievalError)

      @start_vm_id = vm_pool.entries.last.id + 1 unless vm_pool.count == 0

      return vm_pool
    end
  end

  # Check OpenNebula return codes
  def check_retval(rc, e_klass)
    return true unless OpenNebula.is_error?(rc)
    case rc.errno
    when OpenNebula::Error::EAUTHENTICATION
      fail Errors::AuthenticationError, rc.message
    when OpenNebula::Error::EAUTHORIZATION
      fail Errors::UserNotAuthorizedError, rc.message
    when OpenNebula::Error::ENO_EXISTS
      fail Errors::ResourceNotFoundError, rc.message
    when OpenNebula::Error::EACTION
      fail Errors::ResourceStateError, rc.message
    else
      fail e_klass, rc.message
    end
  end

  # Check all hosts and gain benchmark name and value.
  #
  # @return [Hash] hosts' IDs and hash with benchmark name and value
  def benchmark_map
    host_pool = OpenNebula::HostPool.new(@client)
    rc = host_pool.info
    check_retval(rc, Errors::ResourceRetrievalError)

    bench_map = {}

    host_pool.each do |host|
      structure = {}
      benchmark_values = nil
      benchmark_type = nil

      if (benchmark_type = host['TEMPLATE/BENCHMARK_TYPE'])
        benchmark_values = host['TEMPLATE/BENCHMARK_VALUES'].split(/\s*\n\s*/)
      else
        cluster_id = host['CLUSTER_ID'].to_i

        unless cluster_id == -1
          searched_cluster = OpenNebula::Cluster.new(OpenNebula::Cluster.build_xml(cluster_id), @client)
          rc = searched_cluster.info
          check_retval(rc, Errors::ResourceRetrievalError)

          if (benchmark_type = searched_cluster['TEMPLATE/BENCHMARK_TYPE'])
            benchmark_values = searched_cluster['TEMPLATE/BENCHMARK_VALUES'].split(/\s*\n\s*/)
          end
        end
      end

      if benchmark_values
        mixins = {}
        benchmark_values.each do |value|
          values = value.split(/\s+/, 2)
          mixins[values[0]] = values[1]
        end
        structure = { :benchmark_type => benchmark_type, :mixins => mixins }
      end

      bench_map[host['ID']] = structure
    end

    bench_map
  end
end
