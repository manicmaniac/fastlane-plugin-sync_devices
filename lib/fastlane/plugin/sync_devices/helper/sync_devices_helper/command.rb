# frozen_string_literal: true

require 'spaceship/connect_api'

module Fastlane
  module Helper
    module SyncDevicesHelper
      # Namespace to organize command classes.
      module Command
        # Abstract base class of command object.
        #
        # @attr device [Spaceship::ConnectAPI::Device]
        Base = Struct.new(:device) do
          # Communicate with AppStore Connect and change the remote device.
          # @abstract
          # @return [void]
          def run
            # :nocov:
            raise NotImplementedError
            # :nocov:
          end

          # Description of this command.
          # @abstract
          # @return [String]
          def description
            # :nocov:
            raise NotImplementedError
            # :nocov:
          end
        end

        # Command to do nothing.
        class Noop < Base
          # @return (see Base#run)
          def run
            # Does nothing.
          end

          # @return (see Base#description)
          def description
            "Skipped #{device.name} (#{device.udid})"
          end
        end

        # Command to disable an existing device.
        # @see https://developer.apple.com/documentation/appstoreconnectapi/modify_a_registered_device
        class Disable < Base
          # @return (see Base#run)
          def run
            Spaceship::ConnectAPI::Device.disable(device.udid)
          end

          # @return (see Base#description)
          def description
            "Disabled #{device.name} (#{device.udid})"
          end
        end

        # Command to enable an existing device.
        # @see https://developer.apple.com/documentation/appstoreconnectapi/modify_a_registered_device
        class Enable < Base
          # @return (see Base#run)
          def run
            Spaceship::ConnectAPI::Device.enable(device.udid)
          end

          # @return (see Base#description)
          def description
            "Enabled #{device.name} (#{device.udid})"
          end
        end

        # Command to rename an existing device.
        # @see https://developer.apple.com/documentation/appstoreconnectapi/modify_a_registered_device
        class Rename < Base
          # @return [String]
          attr_reader :name

          # @param device [Spaceship::ConnectAPI::Device]
          # @param name [String]
          def initialize(device, name)
            super(device)
            @name = name
          end

          # @return (see Base#run)
          def run
            Spaceship::ConnectAPI::Device.rename(device.udid, name)
          end

          # @return (see Base#description)
          def description
            "Renamed #{device.name} to #{name} (#{device.udid})"
          end
        end

        # Command to disable and rename an existing device.
        # @see https://developer.apple.com/documentation/appstoreconnectapi/modify_a_registered_device
        class DisableAndRename < Base
          # @return [String]
          attr_reader :name

          # @param device [Spaceship::ConnectAPI::Device]
          # @param name [String]
          def initialize(device, name)
            super(device)
            @name = name
          end

          # @return (see Base#run)
          def run
            Spaceship::ConnectAPI::Device.modify(
              device.udid,
              enabled: false,
              new_name: name
            )
          end

          # @return (see Base#description)
          def description
            "Disabled and renamed #{device.name} to #{name} (#{device.udid})"
          end
        end

        # Command to enable and rename an existing device.
        # @see https://developer.apple.com/documentation/appstoreconnectapi/modify_a_registered_device
        class EnableAndRename < Base
          # @return [String] name
          attr_reader :name

          # @param device [Spaceship::ConnectAPI::Device]
          # @param name [String]
          def initialize(device, name)
            super(device)
            @name = name
          end

          # @return (see Base#run)
          def run
            Spaceship::ConnectAPI::Device.modify(
              device.udid,
              enabled: true,
              new_name: name
            )
          end

          # @return (see Base#description)
          def description
            "Enabled and renamed #{device.name} to #{name} (#{device.udid})"
          end
        end

        # Command to register a new device.
        # @see https://developer.apple.com/documentation/appstoreconnectapi/register_a_new_device
        class Create < Base
          # @return (see Base#run)
          def run
            Spaceship::ConnectAPI::Device.create(
              name: device.name,
              platform: device.platform,
              udid: device.udid
            )
          end

          # @return (see Base#description)
          def description
            "Created #{device.name} (#{device.udid})"
          end
        end
      end
    end
  end
end
