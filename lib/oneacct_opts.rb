require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'oneacct_exporter'
require 'settings'

# Class for parsing command line arguments
class OneacctOpts
  include OutputTypes

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

      opts.on('--records-for PERIOD',
              'Retrieves only records within the time PERIOD') do |period|
        options.records_for = period
      end

      opts.on('--include-groups [GROUP1,GROUP2,...]', Array,
              'Retrieves only records of virtual machines which '\
              'belong to the specified groups') do |groups|
        groups = [] unless groups
        options.include_groups = groups
      end

      opts.on('--exclude-groups [GROUP1,GROUP2,...]', Array,
              'Retrieves only records of virtual machines which '\
              "don't belong to the specified groups") do |groups|
        groups = [] unless groups
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

      opts.on('--harden-ssl-security', 'Sets basic SSL options for better security.') do
          OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options] |= OpenSSL::SSL::OP_NO_SSLv2
          OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options] |= OpenSSL::SSL::OP_NO_SSLv3
          OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options] |= OpenSSL::SSL::OP_NO_COMPRESSION
      end

      opts.on('--ssl-cipher-suite CIPHER_SUITE', 'Sets SSL cipher suite.') do |suite|
        OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ciphers] = suite
      end

      opts.on('--ssl-version VERSION', 'Sets SSL version') do |version|
        OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ssl_version] = version
      end

      opts.on("--skip-ca-check", "Skip server certificate verification [NOT recommended]") do
          silence_warnings { OpenSSL::SSL.const_set(:VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE) }
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
    options.timeout = TIMEOUT_DEFAULT if options.blocking unless options.timeout
    options.compatibility = COMPATIBILITY_DEFAULT unless options.compatibility
  end

  def self.check_restrictions(options)
    check_options_restrictions(options)
    check_settings_restrictions
  end

  # Make sure command line parameters are sane
  def self.check_options_restrictions(options)
    # make sure only one time option is used
    if (options.records_from || options.records_to) && options.records_for
      fail ArgumentError, 'Cannot use both time period and time range options.'
    end

    # make sure date range make sense
    if options.records_from && options.records_to && options.records_from >= options.records_to
      fail ArgumentError, 'Wrong time range for records retrieval.'
    end

    # make sure only one group restriction is used
    if options.include_groups && options.exclude_groups
      fail ArgumentError, 'Mixing of group options is not possible.'
    end

    # make sure group file option is not used without specifying group restriction type
    unless options.include_groups || options.exclude_groups
      if options.groups_file
        fail ArgumentError, 'Cannot use group file without specifying group restriction type.'
      end
    end

    # make sure that timeout option is not used without blocking option
    if options.timeout && !options.blocking
      fail ArgumentError, 'Cannot set timeout without a blocking mode.'
    end
  end

  # Make sure configuration is sane
  def self.check_settings_restrictions
    # make sure all mandatory parameters are set
    unless Settings['output'] && Settings.output['output_dir'] && Settings.output['output_type']
      fail ArgumentError, 'Missing some mandatory parameters. Check your configuration file.'
    end

    # make sure log file is specified while loggin to file
    if Settings['logging'] && Settings.logging['log_type'] == 'file' &&
       !Settings.logging['log_file']
      fail ArgumentError, 'Missing file for logging. Check your configuration file.'
    end

    check_output_type_specific_settings

    # make sure specified template really exists
    template_filename = OneWriter.template_filename(Settings.output['output_type'])
    unless File.exist?(template_filename)
      fail ArgumentError, "Non-existing template #{Settings.output['output_type']}."
    end
  end

  def self.check_output_type_specific_settings
    if APEL_OT.include?(Settings.output['output_type'])
      unless Settings.output['apel'] && Settings.output.apel['site_name'] &&
          Settings.output.apel['cloud_type'] && Settings.output.apel['endpoint']
        fail ArgumentError, 'Missing some mandatory parameters for APEL output type. Check your configuration file.'
      end
    end

    if PBS_OT.include?(Settings.output['output_type']) && Settings.output['pbs']
      Settings.output.pbs['realm'] ||= 'META'
      Settings.output.pbs['queue'] ||= 'cloud'
      Settings.output.pbs['scratch_type'] ||= 'local'
      Settings.output.pbs['host_identifier'] ||= 'on_localhost'
    end

    if LOGSTASH_OT.include?(Settings.output['output_type'])
      unless Settings.output['logstash'] && Settings.output.logstash['host'] && Settings.output.logstash['port']
        fail ArgumentError, 'Missing some mandatory parameters for logstash output type. Check your configuration file.'
      end
    end
  end

  def self.silence_warnings
    old_verbose, $VERBOSE = $VERBOSE, nil
    yield
  ensure
    $VERBOSE = old_verbose
  end
end
