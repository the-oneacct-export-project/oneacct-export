require 'oneacct_exporter/version'
require 'opennebula'
require 'one_worker'
require 'settings'
require 'sidekiq/api'

# Class managing the export
#
# @attr_reader [any logger] log logger for the class
# @attr_reader [Hash] range range of dates, requesting only virtual machines within the range
# @attr_reader [Hash] groups user groups, requesting only virtual machines with owners that
# belong to one of the group
# @attr_reader [TrueClass, FalseClass] blocking says whether to run export in blocking mode or not
# @attr_reader [Integer] timeout timeout for blocking mode
# @attr_reader [TrueClass, FalseClass] compatibility says whether to run export in compatibility
# mode or not
class OneacctExporter
  attr_reader :log, :range, :groups, :blocking, :timeout, :compatibility

  def initialize(options, log)
    @log = log
    @range = options[:range]
    @groups = options[:groups]
    @blocking = options[:blocking]
    @timeout = options[:timeout]
    @compatibility = options[:compatibility]
  end

  # Start export the records
  def export
    @log.debug('Starting export...')

    clean_output_dir

    new_file_number = 1
    oda = OneDataAccessor.new(@compatibility, @log)

    vms = []
    # load records of virtual machines in batches
    while vms = oda.vms(@range, @groups)
      unless vms.empty?
        @log.info("Starting worker with next batch.")
        # add a new job for every batch to the Sidekiq's queue
        OneWorker.perform_async(vms.join('|'), new_file_number)
        new_file_number += 1
      end
    end

    @log.info('No more records to read.')

    wait_for_processing if @blocking

    @log.info('Exiting.')
  rescue Errors::AuthenticationError, Errors::UserNotAuthorizedError,\
         Errors::ResourceNotFoundError, Errors::ResourceStateError,\
         Errors::ResourceRetrievalError => e
    @log.error("Virtual machine retrieval "\
               "failed with error: #{e.message}. Exiting.")
  end

  # When in blocking mode, wait for processing of records to finish
  def wait_for_processing
    @log.info('Processing...')

    end_time = Time.new + @timeout

    until queue_empty? && all_workers_done?
      if end_time < Time.new
        @log.error("Processing time exceeded timeout of #{@timeout} seconds.")
        break
      end
      sleep(5)
    end

    @log.info('All processing ended.')
  end

  # Check whether Sidekiq's queue is empty
  def queue_empty?
    queue = (Settings['sidekiq'] && Settings.sidekiq['queue']) ? Settings.sidekiq['queue'] : 'default'
    Sidekiq::Stats.new.queues.each_pair do |queue_name, items_in_queue|
      return items_in_queue == 0 if queue_name == queue
    end

    true
  end

  # Check whether all Sidekiq workers have finished thair work
  def all_workers_done?
    Sidekiq::Workers.new.size == 0
  end

  # Clean output directory of previous entries
  def clean_output_dir
    output_dir = Dir.new(Settings.output['output_dir'])
    entries = output_dir.entries.select { |entry| entry != '.' && entry != '..' }
    entries.each do |entry|
      File.delete("#{output_dir.path}/#{entry}")
    end
  end
end
