require 'erb'
require 'tempfile'
require 'fileutils'

class OneWriter
  CONVERT_FORMAT = "%014d"
  def initialize(data, template, output, log)
    @data = data
    @template = template
    @output = output
    @log = log
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
    output_dir = Dir.new(@output)
    output_file = nil
    last_file = output_dir.entries.sort.last
    unless /[0-9]{14}/ =~ last_file
      output_file = CONVERT_FORMAT % 1
    else
      output_file = CONVERT_FORMAT % (last_file.to_i + 1)
    end
    @log.debug("Copying temporary file into '#{output_file}'")
    FileUtils.cp(tmp.path, "#{@output}/#{output_file}")
    tmp.close
    tmp.unlink
  end
end
