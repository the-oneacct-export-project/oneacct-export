require 'oneacct_exporter/version'
require 'opennebula'
require 'one_worker'
require 'settings'

class OneacctExporter
  CONVERT_FORMAT = '%014d'

  def initialize(options, log)
    @log = log

    @range = {}
    @range[:from] = options.records_from
    @range[:to] = options.records_to

    @groups = {}
    @groups[:include] = options.include_groups if options.include_groups
    @groups[:exclude] = options.exclude_groups if options.exclude_groups

    if options.groups_file
      @log.debug('Reading groups from file...')
      if File.exist?(options.groups_file) && File.readable?(options.groups_file)
        file = File.open(options.groups_file, 'r')
        file.each_line do |line|
          @groups[@groups.keys.first] << line
        end
        file.close
      else
        @log.error("File contaning groups: #{options.groups_file} doesn't exists or cannot be read. "\
                   "Skipping groups restriction...")
        @groups[@groups.keys.first] = []
      end
    end
  end

  def export
    @log.debug('Starting export...')

    new_file_number = last_file_number + 1
    batch_number = 0
    oda = OneDataAccessor.new(@log)

    vms = []
    while vms = oda.vms(batch_number, @range, @groups)
      output_file = CONVERT_FORMAT % new_file_number
      @log.info("Staring worker with batch number: #{batch_number}.")
      unless vms.empty?
        OneWorker.perform_async(vms.join('|'), "#{Settings.output['output_dir']}/#{output_file}")
        new_file_number += 1
      end
      batch_number += 1
    end

    @log.info('No more records. Exiting...')
  rescue => e
    @log.error("Virtual machine retrieval for batch number #{batch_number} "\
               "failed with error: #{e.message}. Exiting.")
  end

  def last_file_number
    output_dir = Dir.new(Settings.output['output_dir'])
    last_file = output_dir.entries.sort.last
    /[0-9]{14}/ =~ last_file ? last_file.to_i : 0
  end
end
