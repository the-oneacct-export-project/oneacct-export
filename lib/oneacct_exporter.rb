require "oneacct_exporter/version"
require 'opennebula'
require 'one_worker'
require 'settings'

class OneacctExporter
  CONVERT_FORMAT = "%014d"

  def initialize(log)
    @log = log

    @range = {}
    @range[:from] = Settings['records_from']
    @range[:to] = Settings['records_to']

    @groups = {}
    if Settings['include_groups']
      @groups[:include] = Settings['include_groups']
    end
    if Settings['exclude_groups']
      @groups[:exclude] = Settings['exclude_groups']
    end

    if Settings['groups_file']
      @log.debug("Reading groups from file...")
      unless File.exists?(Settings['groups_file']) or File.readable?(Settings['groups_file'])
        @log.error("File contaning groups: #{Settings['groups_file']} doesn't exists or cannot be read. Skipping groups restriction...")
        @groups[@groups.keys.first] = []
      else
        file = File.open(Settings['groups_file'], "r")
        file.each_line do |line|
          @groups[@groups.keys.first] << line
        end
        file.close
      end
    end
  end

  def export
    @log.debug("Starting export...")

    common_data = {}
    common_data["endpoint"] = Settings['endpoint']
    common_data["site_name"] = Settings['site_name']
    common_data["cloud_type"] = Settings['cloud_type']

    new_file_number = last_file_number + 1
    batch_number = 0
    oda = OneDataAccessor.new(@log)

    vms = []
    while vms = oda.vms(batch_number, @range, @groups)
      output_file = CONVERT_FORMAT % new_file_number
      @log.debug("Staring worker with batch number: #{batch_number}.")
      unless vms.empty?
        OneWorker.perform_async(vms.join("|"), common_data, Settings['template_filename'], "#{Settings['output']}/#{output_file}")
        new_file_number += 1
      end
      batch_number += 1
    end

    @log.debug("No more records. Exiting...")
  end

  def last_file_number
    output_dir = Dir.new(Settings['output'])
    last_file = output_dir.entries.sort.last
    /[0-9]{14}/ =~ last_file ? last_file.to_i : 0
  end
end
