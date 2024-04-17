# frozen_string_literal: true

module Fastlane
  # @see https://rubydoc.info/gems/fastlane/Fastlane/Helper Fastlane::Helper
  module Helper
    # Root namespace of +fastlane-plugin-sync_devices+ helpers.
    module SyncDevicesHelper
    end
  end
end

require_relative 'sync_devices_helper/devices_file'
require_relative 'sync_devices_helper/devices_patch'
