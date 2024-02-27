require 'spaceship/connect_api'

module Fastlane
  module Helper
    module SyncDevicesHelper
      module Command
        Base = Struct.new(:old_device, :new_device, :description) do
          def run
            raise NotImplementedError
          end
        end

        class Noop < Base
          def initialize(device)
            super(
              old_device: device,
              new_device: device,
              description: "Skipped #{device.name} (#{device.udid})"
            )
          end

          def run
            # Does nothing.
          end
        end

        class Disable < Base
          def initialize(device)
            super(
              old_device: device,
              new_device: nil,
              description: "Disabled #{device.name} (#{device.udid})"
            )
          end

          def run
            Spaceship::ConnectAPI::Device.disable(old_device.udid)
          end
        end

        class Modify < Base
          def initialize(old_device, new_device)
            raise 'Old and new devices must have the same UDID.' if old_device.udid != new_device.udid

            super(
              old_device: old_device,
              new_device: new_device,
              description: nil
            )
          end

          def run
            Spaceship::ConnectAPI::Device.modify(
              new_device.udid,
              enabled: new_device.status == Spaceship::ConnectAPI::Device::Status::ENABLED,
              new_name: new_device.name
            )
          end

          def enabled?
            return false unless old_device && new_device

            old_device.status != new_device.status && new_device.status == Spaceship::ConnectAPI::Device::Status::ENABLED
          end

          def disabled?
            old_device.enabled? && !new_device.enabled?
          end

          def renamed?
            old_device.name != new_device.name
          end

          def description
            @description ||= build_description
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

        class Create < Base
          def initialize(device)
            super(
              old_device: nil,
              new_device: device,
              description: "Created #{device.name} (#{device.udid})"
            )
          end

          def run
            Spaceship::ConnectAPI::Device.create(
              name: new_device.name,
              platform: new_device.platform,
              udid: new_device.udid
            )
          end
        end
      end
    end
  end
end
