require_relative 'command'

module Fastlane
  module Helper
    module SyncDevicesHelper
      class DevicePatch
        NULL_DEVICE = Spaceship::ConnectAPI::Device.new(nil, {
          name: nil,
          platform: nil,
          enabled: false
        }).freeze
        private_constant :NULL_DEVICE

        attr_reader :old_device, :new_device

        # @param [Device, nil] old_device
        # @param [Device, nil] new_device
        def initialize(old_device, new_device)
          @old_device = old_device || NULL_DEVICE
          @new_device = new_device || NULL_DEVICE
        end

        def renamed?
          old_device != NULL_DEVICE && new_device != NULL_DEVICE && old_device.name != new_device.name
        end

        def enabled?
          old_device != NULL_DEVICE && !old_device.enabled? && new_device.enabled?
        end

        def disabled?
          old_device != NULL_DEVICE && old_device.enabled? && !new_device.enabled?
        end

        def created?
          old_device == NULL_DEVICE && new_device.enabled?
        end

        def platform_changed?
          return false if old_device == NULL_DEVICE || new_device == NULL_DEVICE

          old_device.platform != new_device.platform
        end

        def command
          raise UnsupportedOperation.change_platform(old_device, new_device) if platform_changed?

          case [renamed?, enabled?, disabled?, created?]
          when [false, false, false, false]
            Command::Noop.new(old_device)
          when [false, false, false, true]
            Command::Create.new(new_device)
          when [false, false, true, false]
            Command::Disable.new(old_device)
          when [false, true, false, false]
            Command::Enable.new(old_device)
          when [true, false, false, false]
            Command::Rename.new(old_device, new_device.name)
          when [true, false, true, false]
            Command::DisableAndRename.new(old_device, new_device.name)
          when [true, true, false, false]
            Command::EnableAndRename.new(old_device, new_device.name)
          else
            raise UnsupportedOperation.inconsistent_status(old_device, new_device)
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

        def self.inconsistent_status(old_device, new_device)
          new(
            "Cannot change #{old_device} to #{new_device} because of internal inconsistency.",
            old_device,
            new_device
          )
        end
      end
    end
  end
end
