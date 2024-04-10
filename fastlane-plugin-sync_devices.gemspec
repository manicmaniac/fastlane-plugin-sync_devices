require_relative 'lib/fastlane/plugin/sync_devices/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-sync_devices'
  spec.version       = Fastlane::SyncDevices::VERSION
  spec.author        = 'Ryosuke Ito'
  spec.email         = 'rito.0305@gmail.com'

  spec.summary       = 'Synchronize your devices with Apple Developer Portal.'
  spec.homepage      = 'https://github.com/manicmaniac/fastlane-plugin-sync_devices'
  spec.license       = 'MIT'

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.required_ruby_version = '>= 2.7'
end
