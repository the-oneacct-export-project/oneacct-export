#!/usr/bin/env ruby
lib_dir = "#{File.dirname(__FILE__)}/../lib"
$:.unshift(lib_dir) unless $:.include?(lib_dir)

require 'optparse'
require 'optparse/time'
require 'ostruct'
#require 'syslog_logger'
require 'oneacct_exporter'
require 'oneacct_exporter/log'
require 'settings'
require 'fileutils'

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage oneacct-export [options]"
  opts.separator ""
  opts.separator "Mandatory arguments"

  opts.on('-s', "--site-name SITE_NAME",
          "Provider name") do |site_name|
    Settings['site_name'] = site_name
  end

  opts.on('-c', "--cloud-type CLOUD_TYPE",
          "Cloud type") do |cloud_type|
    Settings['cloud_type'] = cloud_type
  end

  opts.on('-e', "--endpoint ENDPOINT",
          "URL of OCCI endpoint") do |endpoint|
    endpoint.chop! if endpoint.end_with?("/")
    Settings['endpoint'] = endpoint
  end

  opts.on('-o', "--output OUTPUT",
          "Output directory") do |output|
    Settings['output'] = output
  end

  opts.on('-t', "--output-type OUTPUT_TYPE",
          "Output type") do |output_type|
    Settings['output_type'] = output_type
  end

  opts.separator ""
  opts.separator "Aditional optional arguments"

  opts.on("--records-from TIME", Time,
          "Retrieves only records newer than TIME") do |time|
    Settings['records_from'] = time
  end

  opts.on("--records-to TIME", Time,
          "Retrieves only records older than TIME") do |time|
    Settings['records_to'] = time
  end

  opts.on("--include-groups GROUP1[,GROUP2,...]", Array,
          "Retrieves only records of virtual machines which belong to the specified groups") do |groups|
    Settings['include_groups'] = groups
  end

  opts.on("--exclude-groups GROUP1[,GROUP2,...]", Array,
          "Retrieves only records of virtual machines which don't belong to the specified groups") do |groups|
    Settings['exclude_groups'] = groups
  end

  opts.on("--group-file FILE",
          "If --include-groups or --exclude-groups specified, loads groups from file FILE") do |file|
    Settings['groups_file'] = file
  end

  opts.on("--log-type LOG_TYPE", [:file, :syslog],
          "Select type of logging (file, syslog)") do |type|
    Settings['log_type'] = type
  end

  opts.on("--log-file FILE",
          "If --log-type=file specified, saves log messages to the FILE") do |file|
    Settings['log_file'] = file
  end

  opts.on_tail('-h', "--help", "Shows this message") do
    puts opts
    exit
  end

  opts.on_tail('-v', "--version", "Shows version") do
    puts OneacctExporter::VERSION
    exit
  end
end

opt_parser.parse!(ARGV)

unless Settings['site_name'] and Settings['cloud_type'] and Settings['endpoint'] and Settings['output'] and Settings['output_type']
  raise ArgumentError.new "Missing some mandatory parameters."
end

if Settings['log_type'] and Settings['log_type'] == :file  and !Settings['log_file']
  raise ArgumentError.new "Missing file for logging."
end

if Settings['records_from'] and Settings['records_to'] and Settings['records_from'] >= Settings['records_to']
  raise ArgumentError.new "Wrong time range for records retrieval."
end

if Settings['include_groups'] and Settings['exclude_groups']
  raise ArgumentError.new "Mixing of group options is not possible."
end

template_filename = "lib/templates/#{Settings['output_type']}.erb"
unless File.exists?(template_filename)
  raise ArgumentError.new "Non-existing template #{Settings['output_type']}."
end
Settings['template_filename'] = template_filename

begin
  FileUtils.mkdir_p Settings['output']
rescue SystemCallError => e
  puts "Cannot create an output directory: #{e.message}. Quitting."
  exit
end

log = Logger.new(STDOUT)

if Settings['log_file']
  begin
    log_file = File.open(Settings['log_file'], File::WRONLY | File::CREAT | File::APPEND)
    log = Logger.new(log_file)
  rescue => e
    OneacctExporter::Log.setup_logging(log)
    log.warn("Unable to create log file #{Settings['log_file']}: #{e.message}. Falling back to STDOUT.")
  end
end

if Settings['log_type'] and Settings['log_type'] == :syslog
  log = SyslogLogger.new('oneacct-export')
end

OneacctExporter::Log.setup_log_level(log)

log.debug("Creating OneacctExporter...")
oneacct_exporter = OneacctExporter.new(log)
oneacct_exporter.export

