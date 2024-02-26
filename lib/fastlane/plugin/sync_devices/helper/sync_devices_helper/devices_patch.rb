require_relative 'command'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    module SyncDevicesHelper
      class DevicesPatch
        attr_reader :old_devices, :new_devices, :commands

        # @param [Array<Spaceship::ConnectAPI::Device>] old_devices
        # @param [Array<Spaceship::ConnectAPI::Device>] new_devices
        def initialize(old_devices, new_devices) # rubocop:disable Metrics/PerceivedComplexity
          @old_devices = old_devices
          @new_devices = new_devices

          old_device_by_udid = old_devices.group_by { |d| d.udid.downcase }.transform_values(&:first)
          new_device_by_udid = new_devices.group_by { |d| d.udid.downcase }.transform_values(&:first)
          @commands = []
          old_device_by_udid.each do |old_udid, old_device|
            new_device = new_device_by_udid[old_udid]
            unless new_device
              if old_device.enabled?
                @commands << Command::Disable.new(old_device)
              else
                @commands << Command::Noop.new(old_device)
              end
              next
            end

            if old_device.platform != new_device.platform
              raise UnsupportedOperation.change_platform(old_device, new_device)
            end

            if old_device.name == new_device.name && old_device.status == new_device.status
              @commands << Command::Noop.new(new_device)
            else
              @commands << Command::Modify.new(old_device, new_device)
            end
          end
          new_device_by_udid.each do |new_udid, new_device|
            unless old_device_by_udid.key?(new_udid)
              @commands << Command::Create.new(new_device)
            end
          end
        end

        # @param [Boolean] dry_run
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

      class UnsupportedOperation < StandardError
        attr_reader :old_device, :new_device

        # @param [String] message
        # @param [Spaceship::ConnectAPI::Device] old_device
        # @param [Spaceship::ConnectAPI::Device] new_device
        def initialize(message, old_device, new_device)
          super(message)
          @old_device = old_device
          @new_device = new_device
        end

        # @param [Spaceship::ConnectAPI::Device] old_device
        # @param [Spaceship::ConnectAPI::Device] new_device
        # @return [UnsupportedOperation]
        def self.change_platform(old_device, new_device)
          new(
            "Channot change platform of the device '#{new_device.udid}' (#{old_device.platform} -> #{new_device.platform})",
            old_device,
            new_device
          )
        end
      end
    end
  end
end
