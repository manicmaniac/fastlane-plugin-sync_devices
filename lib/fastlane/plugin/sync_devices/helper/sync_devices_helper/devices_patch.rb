# frozen_string_literal: true

require_relative 'device_patch'

module Fastlane # rubocop:disable Style/Documentation
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    module SyncDevicesHelper
      # Represents a collection of {DevicePatch}.
      class DevicesPatch
        # @return [Spaceship::ConnectAPI::Device]
        attr_reader :old_devices, :new_devices
        # @return [Array<DevicePatch>]
        attr_reader :commands

        # @param old_devices [Array<Spaceship::ConnectAPI::Device>]
        # @param new_devices [Array<Spaceship::ConnectAPI::Device>]
        def initialize(old_devices, new_devices) # rubocop:disable Metrics/AbcSize
          @old_devices = old_devices
          @new_devices = new_devices

          old_device_by_udid = old_devices.group_by { |d| d.udid.downcase }.transform_values(&:first)
          new_device_by_udid = new_devices.group_by { |d| d.udid.downcase }.transform_values(&:first)
          @commands = (old_device_by_udid.keys + new_device_by_udid.keys)
                      .sort
                      .uniq
                      .map do |udid|
            old_device = old_device_by_udid[udid]
            new_device = new_device_by_udid[udid]
            DevicePatch.new(old_device, new_device).command
          end
        end

        # @param dry_run [Boolean]
        # @return [void]
        def apply!(dry_run: false)
          @commands.each do |command|
            if dry_run
              UI.message("(dry-run) #{command.description}")
            else
              command.run
              UI.message(command.description)
            end
          end
        end
      end
    end
  end
end
