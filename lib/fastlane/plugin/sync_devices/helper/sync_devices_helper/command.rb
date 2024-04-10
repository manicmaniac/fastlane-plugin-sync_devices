require 'spaceship/connect_api'

module Fastlane
  module Helper
    module SyncDevicesHelper
      module Command
        Base = Struct.new(:device) do
          def run
            raise NotImplementedError
          end

          def description
            raise NotImplementedError
          end
        end

        class Noop < Base
          def run
            # Does nothing.
          end

          def description
            "Skipped #{device.name} (#{device.udid})"
          end
        end

        class Disable < Base
          def run
            Spaceship::ConnectAPI::Device.disable(device.udid)
          end

          def description
            "Disabled #{device.name} (#{device.udid})"
          end
        end

        class Enable < Base
          def run
            Spaceship::ConnectAPI::Device.enable(device.udid)
          end

          def description
            "Enabled #{device.name} (#{device.udid})"
          end
        end

        class Rename < Base
          attr_reader :name

          def initialize(device, name)
            super(device)
            @name = name
          end

          def run
            Spaceship::ConnectAPI::Device.rename(device.udid, name)
          end

          def description
            "Renamed #{device.name} to #{name} (#{device.udid})"
          end
        end

        class DisableAndRename < Base
          attr_reader :name

          def initialize(device, name)
            super(device)
            @name = name
          end

          def run
            Spaceship::ConnectAPI::Device.modify(
              device.udid,
              enabled: false,
              new_name: name
            )
          end

          def description
            "Disabled and renamed #{device.name} to #{name} (#{device.udid})"
          end
        end

        class EnableAndRename < Base
          attr_reader :name

          def initialize(device, name)
            super(device)
            @name = name
          end

          def run
            Spaceship::ConnectAPI::Device.modify(
              device.udid,
              enabled: true,
              new_name: name
            )
          end

          def description
            "Enabled and renamed #{device.name} to #{name} (#{device.udid})"
          end
        end

        class Create < Base
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
