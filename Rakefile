require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

task(default: [:spec, :rubocop])

file 'spec/support/fixtures/api_key.json' do |f|
  require 'json'
  require 'openssl'

  File.write(f.name, JSON.pretty_generate({
    key_id: 'TEST',
    issuer_id: 'TEST',
    key: OpenSSL::PKey::EC.generate('prime256v1').export.chomp,
    duration: 500,
    in_house: false
  }))
end
