require 'spaceship/connect_api'

module Fastlane
  module Helper
    module SyncDevicesHelper
      module Command
        class Noop
          attr_reader :device

          def initialize(device)
            @device = device
          end

          def run
            # Does nothing.
          end

          def description
            "Skipped #{device.name} (#{device.udid})"
          end
        end

        class Disable
          attr_reader :device

          def initialize(device)
            @device = device
          end

          def run
            Spaceship::ConnectAPI::Device.disable(device.udid)
          end

          def description
            "Disabled #{device.name} (#{device.udid})"
          end
        end

        class Modify
          attr_reader :old_device, :new_device, :description

          def initialize(old_device, new_device)
            raise 'Old and new devices must have the same UDID.' if old_device.udid != new_device.udid

            @old_device = old_device
            @new_device = new_device
            @description = build_description
          end

          def run
            Spaceship::ConnectAPI::Device.modify(
              new_device.udid,
              enabled: new_device.status == Spaceship::ConnectAPI::Device::Status::ENABLED,
              new_name: new_device.name
            )
          end

          def enabled?
            old_device.status != new_device.status && new_device.status == Spaceship::ConnectAPI::Device::Status::ENABLED
          end

          def disabled?
            old_device.status != new_device.status && new_device.status == Spaceship::ConnectAPI::Device::Status::DISABLED
          end

          def renamed?
            old_device.name != new_device.name
          end

          private

          def build_description
            case [enabled?, disabled?, renamed?]
            when [false, false, false]
              raise 'It must be Command::Noop'
            when [false, false, true]
              "Renamed from #{old_device.name} to #{new_device.name} (#{new_device.udid})"
            when [false, true, false]
              raise 'It must be Command::Disable'
            when [false, true, true]
              "Disabled and renamed from #{old_device.name} to #{new_device.name} (#{new_device.udid})"
            when [true, false, false]
              "Enabled #{new_device.name} (#{new_device.udid})"
            when [true, false, true]
              "Enabled and renamed from #{old_device.name} to #{new_device.name} (#{new_device.udid})"
            when [true, true, false], [true, true, true]
              raise 'enabled? and disabled? is mutually exclusive'
            end
          end
        end

        class Create
          attr_reader :device

          def initialize(device)
            @device = device
          end

          def run
            Spaceship::ConnectAPI::Device.create(
              name: device.name,
              platform: device.platform,
              udid: device.udid
            )
          end

          def description
            "Created #{device.name} (#{device.udid})"
          end
        end
      end
    end
  end
end
