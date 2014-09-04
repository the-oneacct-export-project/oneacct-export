ENV['RAILS_ENV'] = 'test'
require 'one_writer'
require 'redis_conf'
require 'one_data_accessor'
require 'oneacct_exporter'
require 'sidekiq/testing'
GEM_DIR = File.realdirpath("#{File.dirname(__FILE__)}/..")
