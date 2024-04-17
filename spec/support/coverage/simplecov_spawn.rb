# frozen_string_literal: true

# @see https://github.com/simplecov-ruby/simplecov/blob/v0.21.2/README.md#running-simplecov-against-spawned-subprocesses
# @see https://github.com/simplecov-ruby/simplecov/issues/1085

require 'simplecov'

SimpleCov.command_name(File.basename(Process.argv0))
SimpleCov.enable_coverage :branch
SimpleCov.at_fork.call(Process.pid)
