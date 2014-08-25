require 'erb'
require 'tempfile'
require 'fileutils'
require 'settings'

class OneWriter
  def initialize(data, template, output, log)
    @data = data
    @output = output
    @log = log
    @template = template

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
end
