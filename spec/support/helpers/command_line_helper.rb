# frozen_string_literal: true

require 'rubygems'

module CommandLineHelper
  RUBY_ARGS = [
    RbConfig.ruby,
    '-r',
    File.expand_path('../coverage/simplecov_spawn', __dir__)
  ].freeze
  private_constant :RUBY_ARGS

  # Define wrapper methods of {Kernel#spawn} and {Kernel#system} to collect code coverage in subprocesses.
  %i[spawn system].each do |method_name|
    define_method(:"#{method_name}_ruby") do |env, *args, **kwargs|
      Kernel.public_send(method_name, env, *RUBY_ARGS, *args, **kwargs)
    end
  end
end
