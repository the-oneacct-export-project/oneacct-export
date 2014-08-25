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

options = OpenStruct.new

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage oneacct-export [options]"
  opts.separator ""

  opts.on("--records-from TIME", Time,
          "Retrieves only records newer than TIME") do |time|
    options.records_from = time
  end

  opts.on("--records-to TIME", Time,
          "Retrieves only records older than TIME") do |time|
    options.records_to = time
  end

  opts.on("--include-groups GROUP1[,GROUP2,...]", Array,
          "Retrieves only records of virtual machines which belong to the specified groups") do |groups|
    options.include_groups = groups
  end

  opts.on("--exclude-groups GROUP1[,GROUP2,...]", Array,
          "Retrieves only records of virtual machines which don't belong to the specified groups") do |groups|
    options.exclude_groups = groups
  end

  opts.on("--group-file FILE",
          "If --include-groups or --exclude-groups specified, loads groups from file FILE") do |file|
    options.groups_file = file
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

unless Settings['site_name'] and Settings['cloud_type'] and Settings['endpoint'] and Settings['output'] and Settings.output['output_dir'] and Settings.output['output_type']
  raise ArgumentError.new "Missing some mandatory parameters. Check your configuration file."
end
Settings['endpoint'].chop! if Settings['endpoint'].end_with?("/")

if Settings['logging'] and Settings['logging']['log_type'] == :file.to_s  and !Settings['logging']['log_file']
  raise ArgumentError.new "Missing file for logging. Check your configuration file."
end

if options.records_from and options.records_to and options.records_from >= options.records_to
  raise ArgumentError.new "Wrong time range for records retrieval."
end

if options.include_groups and options.exclude_groups
  raise ArgumentError.new "Mixing of group options is not possible."
end

template_filename = OneWriter.template_filename(Settings.output['output_type'])
unless File.exists?(template_filename)
  raise ArgumentError.new "Non-existing template #{Settings.output['output_type']}."
end

begin
  FileUtils.mkdir_p Settings.output['output_dir']
rescue SystemCallError => e
  puts "Cannot create an output directory: #{e.message}. Quitting."
  exit
end

log = Logger.new(STDOUT)

if Settings['logging'] and Settings['logging']['log_file'] and Settings['logging']['log_type'] == :file.to_s
  begin
    log_file = File.open(Settings['logging']['log_file'], File::WRONLY | File::CREAT | File::APPEND)
    log = Logger.new(log_file)
  rescue => e
    OneacctExporter::Log.setup_logging(log)
    log.warn("Unable to create log file #{Settings['logging']['log_file']}: #{e.message}. Falling back to STDOUT.")
  end
end

if Settings['logging'] and Settings['logging']['log_type'] == :syslog.to_s
  log = SyslogLogger.new('oneacct-export')
end

OneacctExporter::Log.setup_log_level(log)

log.debug("Creating OneacctExporter...")
oneacct_exporter = OneacctExporter.new(options, log)
oneacct_exporter.export

