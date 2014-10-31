require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'oneacct_exporter'
require 'settings'

# Class for parsing command line arguments
class OneacctOpts
  BLOCKING_DEFAULT = false
  TIMEOUT_DEFAULT = 60 * 60
  COMPATIBILITY_DEFAULT = false

  def self.parse(args)
    options = OpenStruct.new

    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Usage oneacct-export [options]'
      opts.separator ''

      opts.on('--records-from TIME', Time,
              'Retrieves only records newer than TIME') do |time|
        options.records_from = time
      end

      opts.on('--records-to TIME', Time,
              'Retrieves only records older than TIME') do |time|
        options.records_to = time
      end

      opts.on('--include-groups GROUP1[,GROUP2,...]', Array,
              'Retrieves only records of virtual machines which '\
              'belong to the specified groups') do |groups|
        options.include_groups = groups
      end

      opts.on('--exclude-groups GROUP1[,GROUP2,...]', Array,
              'Retrieves only records of virtual machines which '\
              "don't belong to the specified groups") do |groups|
        options.exclude_groups = groups
      end

      opts.on('--group-file FILE',
              'If --include-groups or --exclude-groups specified, '\
              'loads groups from file FILE') do |file|
        options.groups_file = file
      end

      opts.on('-b', '--[no-]blocking', 'Run in a blocking mode - '\
              'wait until all submitted jobs are processed') do |blocking|
        options.blocking = blocking
      end

      opts.on('-t', '--timeout N', Integer, 'Timeout for blocking mode in seconds. '\
              'Default is 1 hour.') do |timeout|
        options.timeout = timeout
      end

      opts.on('-c', '--[no-]compatibility-mode', 'Run in compatibility mode - '\
              'supports OpenNebula 4.4.x') do |compatibility|
        options.compatibility = compatibility
      end

      opts.on_tail('-h', '--help', 'Shows this message') do
        puts opts
        exit
      end

      opts.on_tail('-v', '--version', 'Shows version') do
        puts OneacctExporter::VERSION
        exit
      end
    end

    opt_parser.parse!(args)
    set_defaults(options)

    check_restrictions(options)

    options
  end

  # Set default values for not specified options
  def self.set_defaults(options)
    options.blocking = BLOCKING_DEFAULT unless options.blocking
    unless options.timeout
      options.timeout = TIMEOUT_DEFAULT if options.blocking
    end
    options.compatibility = COMPATIBILITY_DEFAULT unless options.compatibility
  end

  def self.check_restrictions(options)
    check_options_restrictions(options)
    check_settings_restrictions
  end

  # Make sure command line parameters are sane
  def self.check_options_restrictions(options)
    #make sure date range make sense
    if options.records_from && options.records_to && options.records_from >= options.records_to
      fail ArgumentError, 'Wrong time range for records retrieval.'
    end

    #make sure only one group restriction is used
    if options.include_groups && options.exclude_groups
      fail ArgumentError, 'Mixing of group options is not possible.'
    end

    #make sure group file option is not used without specifying group restriction type
    unless options.include_groups || options.exclude_groups
      if options.groups_file
        fail ArgumentError, 'Cannot use group file without specifying group restriction type.'
      end
    end

    #make sure that timeout option is not used without blocking option
    if options.timeout && !options.blocking
      fail ArgumentError, 'Cannot set timeout without a blocking mode.'
    end
  end

  # Make sure configuration is sane
  def self.check_settings_restrictions
    #make sure all mandatory parameters are set
    unless Settings['site_name'] && Settings['cloud_type'] && Settings['endpoint'] &&
        Settings['output'] && Settings.output['output_dir'] && Settings.output['output_type']
      fail ArgumentError, 'Missing some mandatory parameters. Check your configuration file.'
    end
    Settings['endpoint'].chop! if Settings['endpoint'].end_with?('/')

    #make sure log file is specified while loggin to file
    if Settings['logging'] && Settings.logging['log_type'] == 'file' &&
        !Settings.logging['log_file']
      fail ArgumentError, 'Missing file for logging. Check your configuration file.'
    end

    #make sure specified template really exists
    template_filename = OneWriter.template_filename(Settings.output['output_type'])
    unless File.exist?(template_filename)
      fail ArgumentError, "Non-existing template #{Settings.output['output_type']}."
    end
  end
end
