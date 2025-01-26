# frozen_string_literal: true

# @see https://github.com/simplecov-ruby/simplecov/blob/v0.21.2/README.md#running-simplecov-against-spawned-subprocesses
# @see https://github.com/simplecov-ruby/simplecov/issues/1085

require 'simplecov'

SimpleCov.command_name(File.basename(Process.argv0))
SimpleCov.enable_coverage :branch
# Do not enable `enable_for_subprocesses` because it causes issues with test cases that use nested subprocesses.
# For more details, refer to '../../../bin/start_server'.
# SimpleCov.enable_for_subprocesses true
SimpleCov.at_fork.call(Process.pid)
