require_relative 'sync_devices/version'
require_relative 'sync_devices/actions/sync_devices_action'

module Fastlane
  module SyncDevices
    def self.all_classes
      Dir[File.expand_path('**/{actions,helper}/*.rb', __dir__)]
    end
  end
end

Fastlane::SyncDevices.all_classes.each do |current|
  require current
end
