require 'bundler/gem_tasks'
require 'rubygems/tasks'

task :default => 'test'

desc "Run all tests; includes rspec and coverage reports"
task :test => 'rcov:rspec'

desc "Run all tests; includes rspec and coverage reports"
task :spec => 'test'

Gem::Tasks.new(:build => {:tar => true, :zip => true}, :sign => {:checksum => true, :pgp => false})

namespace :rcov do
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:rspec)
end
