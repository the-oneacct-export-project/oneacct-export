require 'erb'
require 'tempfile'
require 'fileutils'
require 'settings'

class OneWriter
  def initialize(data, output, log)
    @data = data
    @output = output
    @log = log
    @template = OneWriter.template_filename(Settings.output['output_type'])

  end

  def write
    @log.debug("Reading erb template from file: '#{@template}'.")
    erb = ERB.new(File.read(@template), nil, '-')
    erb.filename = @template
    @log.debug("Creating temporary file...")
    tmp = Tempfile.new("oneacct_export") 
    @log.debug("Temporary file: '#{tmp.path}' created.")
    result = erb.result(binding)
    #@log.debug("Result from template: #{result}")
    @log.debug("Writing to temporary file...")
    tmp.write(result)
    tmp.flush
    @log.debug("Copying temporary file into '#{@output}'")
    FileUtils.cp(tmp.path, "#{@output}")
    tmp.close
    tmp.unlink
  end

  def self.template_filename(template_name)
    "lib/templates/#{template_name}.erb"
  end
end
