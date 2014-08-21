require 'opennebula'

class OneDataAccessor
  BATCH_SIZE = 500
  STATE_DONE = '6'

  def initialize(log)
    @log = log
    @client = OpenNebula::Client.new
  end

  def mapping(pool_class, xpath)
    @log.debug("Generating mapping for class: #{pool_class} and xpath: '#{xpath}'.")
    pool = pool_class.new(@client)
    if pool.respond_to? "info_all"
      pool.info_all
    else
      pool.info
    end

    map = {}
    pool.each do |item|
      map[item['ID']] = item[xpath]
    end

    map
  end

  def vm(vm_id)
    @log.debug("Retrieving virtual machine with id: #{vm_id}.")
    vm = OpenNebula::VirtualMachine.new(OpenNebula::VirtualMachine.build_xml(vm_id), @client)
    vm.info
    vm
  end

  def vms(batch_number, range, groups)
    vms = []
    vm_pool = load_vm_pool(batch_number)
    if vm_pool.count == 0
      return nil
    end

    @log.debug("Searching for vms based on range: #{range} and groups: #{groups}.")
    vm_pool.each do |vm|
      unless vm['ID']
        @log.error("Skipping a record without an ID present.")
        next
      end

      #range restriction
      next if range[:from] and vm['STATE'] == STATE_DONE and vm['ETIME'].to_i < range[:from].to_i
      next if range[:to] and vm['STIME'].to_i > range[:to].to_i

      #groups restriction
      next if groups[:include] and !groups[:include].include? vm['GNAME']
      next if groups[:exclude] and groups[:exclude].include? vm['GNAME']

      vms << vm['ID'].to_i
    end

    @log.debug("Selected vms: #{vms}")
    vms
  end

  def load_vm_pool(batch_number)
    @log.debug("Loading vm pool with batch number: #{batch_number}.")
    from = batch_number * BATCH_SIZE
    to = (batch_number + 1) * BATCH_SIZE - 1
    vm_pool = OpenNebula::VirtualMachinePool.new(@client)
    vm_pool.info(OpenNebula::Pool::INFO_ALL, from, to, OpenNebula::VirtualMachinePool::INFO_ALL_VM)
    vm_pool
  end
end

