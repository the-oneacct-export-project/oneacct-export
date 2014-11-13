# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'oneacct_exporter/version'

Gem::Specification.new do |spec|
  spec.name          = 'oneacct-export'
  spec.version       = OneacctExporter::VERSION
  spec.authors       = ['Michal Kimle']
  spec.email         = ['kimle.michal@gmail.com']
  spec.summary       = 'Exporting OpenNebula accounting data.  '
  spec.description   = 'Exporting OpenNebula accounting data.  '
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files                 = `git ls-files -z`.split("\x0")
  spec.executables           = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files            = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths         = ['lib']
  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0.0'
  spec.add_development_dependency 'simplecov', '~> 0.9.0'
  spec.add_development_dependency 'rubygems-tasks', '~> 0.2.4'

  spec.add_runtime_dependency 'opennebula', '~> 4.6.0'
  spec.add_runtime_dependency 'syslogger', '~> 1.6.0'
  spec.add_runtime_dependency 'sidekiq', '~> 3.2.6'
  spec.add_runtime_dependency 'settingslogic', '~> 2.0.9'
end
