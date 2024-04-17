# frozen_string_literal: true

require_relative 'sync_devices/version'
require_relative 'sync_devices/actions/sync_devices_action'

module Fastlane
  # Root namespace of +fastlane-plugin-sync_devices+ plugin.
  module SyncDevices
    # @return [Array<String>]
    def self.all_classes
      Dir[File.expand_path('**/{actions,helper}/*.rb', __dir__)]
    end
  end
end

Fastlane::SyncDevices.all_classes.each do |current|
  require current
end
