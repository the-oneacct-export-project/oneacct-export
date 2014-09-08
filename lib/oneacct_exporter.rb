require 'oneacct_exporter/version'
require 'opennebula'
require 'one_worker'
require 'settings'
require 'sidekiq/api'

class OneacctExporter
  CONVERT_FORMAT = '%014d'

  attr_reader :log, :range, :groups, :blocking, :timeout, :compatibility

  def initialize(options, log)
    @log = log
    @range = options[:range]
    @groups = options[:groups]
    @blocking = options[:blocking]
    @timeout = options[:timeout]
    @compatibility = options[:compatibility]
  end

  def export
    @log.debug('Starting export...')

    clean_output_dir

    new_file_number = 1
    batch_number = 0
    oda = OneDataAccessor.new(@compatibility, @log)

    vms = []
    while vms = oda.vms(batch_number, @range, @groups)
      output_file = CONVERT_FORMAT % new_file_number
      @log.info("Starting worker with batch number: #{batch_number}.")
      unless vms.empty?
        OneWorker.perform_async(vms.join('|'), "#{Settings.output['output_dir']}/#{output_file}")
        new_file_number += 1
      end
      batch_number += 1
    end

    @log.info('No more records to read.')

    wait_for_processing if @blocking

    @log.info('Exiting.')
  rescue Errors::AuthenticationError, Errors::UserNotAuthorizedError,\
    Errors::ResourceNotFoundError, Errors::ResourceStateError,\
    Errors::ResourceRetrievalError => e
    @log.error("Virtual machine retrieval for batch number #{batch_number} "\
               "failed with error: #{e.message}. Exiting.")
  end

  def wait_for_processing
    @log.info('Processing...')

    end_time = Time.new + @timeout

    until queue_empty? && all_workers_done? do
      if end_time < Time.new
        @log.error("Processing time exceeded timeout of #{@timeout} seconds.")
        break
      end
      sleep(5)
    end

    @log.info('All processing ended.')
  end

  def queue_empty?
    queue = (Settings['sidekiq'] && Settings.sidekiq['queue']) ? Settings.sidekiq['queue'] : 'default'
    Sidekiq::Stats.new.queues.each_pair do |queue_name, items_in_queue|
      if queue_name == queue
        return items_in_queue == 0
      end
    end

    true
  end

  def all_workers_done?
    Sidekiq::Workers.new.size == 0
  end

  def clean_output_dir
    output_dir = Dir.new(Settings.output['output_dir'])
    output_dir.entries.each do |entry|
      File.delete("#{Settings.output['output_dir']}/#{entry}") if /[0-9]{14}/ =~ entry
    end
  end
end
