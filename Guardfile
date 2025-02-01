# frozen_string_literal: true

guard :rspec, cmd: 'bundle exec rspec', run_all: { cmd: 'bundle exec rspec' } do
  require 'guard/rspec/dsl'
  dsl = Guard::RSpec::Dsl.new(self)

  rspec = dsl.rspec
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(%r{^spec/support/(?!(coverage)/).+\.rb$}) { rspec.spec_dir }
  watch('bin/start_server') { %w[spec/bin/start_server_spec.rb spec/system] }
  watch('server/app.rb') { %w[spec/server/app_spec.rb spec/server/app_system_spec.rb spec/system] }
  watch('server/proxy.rb') { 'spec/system' }
  watch(rspec.spec_files)

  ruby = dsl.ruby
  dsl.watch_spec_files_for(ruby.lib_files)
end

guard :rubocop, cli: '-D' do
  watch(/(Danger|Gem|Guard|Rake|Fast|Plugin)file$/)
  watch(/.+\.rb$/)
  watch(/.+\.gemspec$/)
  watch(%r{(?:.+/)?\.rubocop(?:_todo)?\.yml$}) { |m| File.dirname(m[0]) }
end
