# frozen_string_literal: true

require_relative 'command'

module Fastlane
  module Helper
    module SyncDevicesHelper
      # Represents differences between 2 devices.
      class DevicePatch
        # @return [Spaceship::ConnectAPI::Device]
        attr_reader :old_device, :new_device

        # @param old_device [Spaceship::ConnectAPI::Device, nil]
        # @param new_device [Spaceship::ConnectAPI::Device, nil]
        def initialize(old_device, new_device)
          @old_device = old_device
          @new_device = new_device
        end

        # @return [Boolean]
        def renamed?
          !!old_device && !!new_device && old_device.name != new_device.name
        end

        # @return [Boolean]
        def enabled?
          !!old_device && !old_device.enabled? && !!new_device&.enabled?
        end

        # @return [Boolean]
        def disabled?
          !!old_device && old_device.enabled? && !new_device&.enabled?
        end

        # @return [Boolean]
        def created?
          old_device.nil? && !!new_device&.enabled?
        end

        # @return [Boolean]
        def platform_changed?
          !!old_device && !!new_device && old_device.platform != new_device.platform
        end

        # @return [Command::Base]
        # @raise [UnsupportedOperation]
        def command # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
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
            # :nocov:
            raise UnsupportedOperation.internal_inconsistency(self, old_device, new_device)
            # :nocov:
          end
        end
      end

      # Generic error that is raised if no operation is defined in AppStore Connect API for diff of devices.
      class UnsupportedOperation < StandardError
        # @return [Spaceship::ConnectAPI::Device]
        attr_reader :old_device, :new_device

        # @param message [String]
        # @param old_device [Spaceship::ConnectAPI::Device]
        # @param new_device [Spaceship::ConnectAPI::Device]
        def initialize(message, old_device, new_device)
          super(message)
          @old_device = old_device
          @new_device = new_device
        end

        # @param old_device [Spaceship::ConnectAPI::Device]
        # @param new_device [Spaceship::ConnectAPI::Device]
        # @return [UnsupportedOperation]
        def self.change_platform(old_device, new_device)
          message = "Cannot change platform of the device '#{new_device.udid}' " \
                    "(#{old_device.platform} -> #{new_device.platform})"
          new(message, old_device, new_device)
        end

        # @param patch [DevicePatch]
        # @param old_device [Spaceship::ConnectAPI::Device]
        # @param new_device [Spaceship::ConnectAPI::Device]
        # @return [UnsupportedOperation]
        def self.internal_inconsistency(patch, old_device, new_device)
          info = {
            renamed?: patch.renamed?,
            enabled?: patch.enabled?,
            disabled?: patch.disabled?,
            created?: patch.created?
          }
          new(
            "Cannot change #{old_device} to #{new_device} because of internal inconsistency. #{info}",
            old_device,
            new_device
          )
        end
      end
    end
  end
end
