require 'oneacct_exporter/version'
require 'opennebula'
require 'one_worker'
require 'settings'

class OneacctExporter
  CONVERT_FORMAT = '%014d'

  attr_reader :log, :range, :groups

  def initialize(range, groups, log)
    @log = log
    @range = range
    @groups = groups
  end

  def export
    @log.debug('Starting export...')

    clean_output_dir

    new_file_number = 1
    batch_number = 0
    oda = OneDataAccessor.new(@log)

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

    @log.info('No more records. Exiting...')
  rescue => e
    @log.error("Virtual machine retrieval for batch number #{batch_number} "\
               "failed with error: #{e.message}. Exiting.")
  end

  def clean_output_dir
    output_dir = Dir.new(Settings.output['output_dir'])
    output_dir.entries.each do |entry|
      File.delete("#{Settings.output['output_dir']}/#{entry}") if /[0-9]{14}/ =~ entry
    end
  end
end
