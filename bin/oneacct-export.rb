#!/usr/bin/env ruby
lib_dir = "#{File.dirname(__FILE__)}/../lib"
$:.unshift(lib_dir) unless $:.include?(lib_dir)

require 'optparse'
require 'optparse/time'
require 'ostruct'
#require 'syslog_logger'
require 'oneacct_exporter'
require 'fileutils'

options = OpenStruct.new

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage oneacct-export [options]"
  opts.separator ""
  opts.separator "Mandatory arguments"

  opts.on('-s', "--site-name SITE_NAME",
          "Provider name") do |site_name|
    options.site_name = site_name
  end

  opts.on('-c', "--cloud-type CLOUD_TYPE",
          "Cloud type") do |cloud_type|
    options.cloud_type = cloud_type
  end

  opts.on('-e', "--endpoint ENDPOINT",
          "URL of OCCI endpoint") do |endpoint|
    endpoint.chop! if endpoint.end_with?("/")
    options.endpoint = endpoint
  end

  opts.on('-o', "--output OUTPUT",
          "Output directory") do |output|
    options.output = output
  end

  opts.on('-t', "--output-type OUTPUT_TYPE",
          "Output type") do |output_type|
    options.output_type = output_type
  end

  opts.separator ""
  opts.separator "Aditional optional arguments"

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

  opts.on("--log-type LOG_TYPE", [:file, :syslog],
          "Select type of logging (file, syslog)") do |type|
    options.log_type = type
  end

  opts.on("--log-file FILE",
          "If --log-type=file specified, saves log messages to the FILE") do |file|
    options.log_file = file
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

puts "Options: #{options.inspect}."

unless options.site_name and options.cloud_type and options.endpoint and options.output and options.output_type
  raise ArgumentError.new "Missing some mandatory parameters."
end

if options.log_type and options.log_type == :file  and !options.log_file
  raise ArgumentError.new "Missing file for logging."
end

if options.records_from and options.records_to and options.records_from >= options.records_to
  raise ArgumentError.new "Wrong time range for records retrieval."
end

if options.include_groups and options.exclude_groups
  raise ArgumentError.new "Mixing of group options is not possible."
end

template_filename = "lib/templates/#{options.output_type}.erb"
unless File.exists?(template_filename)
  raise ArgumentError.new "Non-existing template #{options.output_type}."
end
options.template_filename = template_filename
options.delete_field('output_type')

begin
  FileUtils.mkdir_p options.output
rescue SystemCallError => e
  puts "Cannot create an output directory: #{e.message}. Quitting."
  exit
end

LOG_LEVEL = Logger::DEBUG
log = Logger.new(STDOUT)
log.level = LOG_LEVEL

if options.log_file
  begin
    log_file = File.open(options.log_file, File::WRONLY | File::CREAT | File::APPEND)
    log = Logger.new(log_file)
  rescue => e
    log.warn("Unable to create log file #{options.log_file}: #{e.message}. Falling back to STDOUT.")
  end
end

if options.log_type and options.log_type == :syslog
  log = SyslogLogger.new('oneacct-export')
end

log.level = LOG_LEVEL

Sidekiq::Logging.logger.level = LOG_LEVEL

options.delete_field('log_type') if options.log_type
options.delete_field('log_file') if options.log_file

log.debug("Creating OneacctExporter...")
oneacct_exporter = OneacctExporter.new(options, log)
oneacct_exporter.export

