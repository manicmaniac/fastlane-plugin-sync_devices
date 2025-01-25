# frozen_string_literal: true

require_relative 'lib/fastlane/plugin/sync_devices/version'

Gem::Specification.new do |spec|
  spec.name = 'fastlane-plugin-sync_devices'
  spec.version = Fastlane::SyncDevices::VERSION
  spec.author = 'Ryosuke Ito'
  spec.email = 'rito.0305@gmail.com'
  spec.description = 'Synchronize your devices with Apple Developer Portal.'
  spec.summary = spec.description
  spec.homepage = 'https://github.com/manicmaniac/fastlane-plugin-sync_devices'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'
  spec.metadata = {
    'documentation_uri' => 'https://www.rubydoc.info/gems/fastlane-plugin-sync_devices',
    'bug_tracker_uri' => 'https://github.com/manicmaniac/fastlane-plugin-sync_devices/issues',
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => 'https://github.com/manicmaniac/fastlane-plugin-sync_devices'
  }
  spec.files = Dir['lib/**/*'] + %w[CHANGELOG.md LICENSE README.md]
  spec.require_paths = ['lib']
end
