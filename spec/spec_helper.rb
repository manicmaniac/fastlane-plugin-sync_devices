# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'simplecov'
require 'simplecov-lcov'

# https://github.com/ryanluker/vscode-coverage-gutters/tree/v2.12.0/example/ruby#installation
SimpleCov::Formatter::LcovFormatter.config do |c|
  c.report_with_single_file = true
  c.output_directory = 'coverage'
  c.lcov_file_name = 'lcov.info'
end

SimpleCov.start do
  load_profile 'test_frameworks'
  enable_coverage :branch
  primary_coverage :branch
  formatter SimpleCov::Formatter::MultiFormatter.new([SimpleCov::Formatter::LcovFormatter,
                                                      SimpleCov::Formatter::HTMLFormatter])
end

# This module is only used to check the environment is currently a testing env
module SpecHelper
end

require 'fastlane' # to import the Action super class
require 'fastlane/plugin/sync_devices' # import the actual plugin
require 'support/helpers'

Fastlane.load_actions # load other actions (in case your plugin calls other actions or shared values)

RSpec.configure do |config|
  config.filter_run_when_matching(:focus)
end
