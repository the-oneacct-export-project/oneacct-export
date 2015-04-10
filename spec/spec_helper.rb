require 'simplecov'
SimpleCov.start do
  add_filter "/vendor/"
end

ENV['RAILS_ENV'] = 'test'
require 'one_writer'
require 'redis_conf'
require 'one_data_accessor'
require 'oneacct_exporter'
require 'sidekiq/testing'
require 'oneacct_opts'
require 'data_validators/data_validator'
require 'data_validators/apel_data_validator'
require 'data_validators/data_compute'
require 'data_validators/data_validator_helper'
require 'data_validators/pbs_data_validator'
GEM_DIR = File.realdirpath("#{File.dirname(__FILE__)}/..")
