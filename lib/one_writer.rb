require 'erb'
require 'tempfile'
require 'fileutils'
require 'settings'
require 'logger'

# Class responsible for writing data into files in specific format
#
# @attr_reader [Hash] data vm data
# @attr_reader [String] output path to the output directory
# @attr_reader [any logger] logger
class OneWriter

  attr_reader :data, :output, :log

  def initialize(data, output, log = Logger.new(STDOUT))
    fail ArgumentError, 'Data and output cannot be nil' if data.nil? || output.nil?

    @template = OneWriter.template_filename(Settings.output['output_type']) if Settings['output']
    fail ArgumentError, "No such file: #{@template}." unless File.exist?(@template)

    @data = data
    @output = output
    @log = log
  end

  # Write data to file in output directory
  def write
    @log.debug('Creating temporary file...')
    tmp = Tempfile.new('oneacct_export')
    @log.debug("Temporary file: '#{tmp.path}' created.")
    @log.debug('Writing to temporary file...')
    write_to_tmp(tmp, fill_template)
    copy_to_output(tmp.path, @output)
  ensure
    tmp.close(true)
  end

  def write_to_tmp(tmp, data)
    tmp.write(data)
    tmp.flush
  end

  def copy_to_output(from, to)
    @log.debug("Copying temporary file into '#{@output}'")
    FileUtils.cp(from, to)
  end

  # Prepare file content according to ERB template
  #
  # @return [String] transformed content
  def fill_template
    @log.debug("Reading erb template from file: '#{@template}'.")
    erb = ERB.new(File.read(@template), nil, '-')
    erb.filename = @template
    erb.result(binding)
  end

  # Load template for data conversion
  #
  # @param [String] template_name name of the template to look for
  def self.template_filename(template_name)
    "#{File.dirname(__FILE__)}/templates/#{template_name}.erb"
  end
end
