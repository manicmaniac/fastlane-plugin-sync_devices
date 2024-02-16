Device = Spaceship::ConnectAPI::Device
Platform = Spaceship::ConnectAPI::Platform

module Fastlane::Helper::SyncDevicesHelper
  describe DevicesPatch do
    describe '#apply!' do
      context 'with dry_run: true' do
        old_devices = [
          Device.new('0', { name: 'NAME0', udid: 'UDID0', platform: Platform::IOS, status: Device::Status::ENABLED }),
          Device.new('1', { name: 'NAME1', udid: 'UDID1', platform: Platform::IOS, status: Device::Status::ENABLED }),
          Device.new('2', { name: 'NAME2', udid: 'UDID2', platform: Platform::IOS, status: Device::Status::DISABLED }),
          Device.new('3', { name: 'NAME3', udid: 'UDID3', platform: Platform::MAC_OS, status: Device::Status::ENABLED }),
          Device.new('4', { name: 'NAME4', udid: 'UDID4', platform: Platform::MAC_OS, status: Device::Status::ENABLED })
        ]

        new_devices = [
          Device.new('0', { name: 'NAME0', udid: 'UDID0', platform: Platform::IOS, status: Device::Status::ENABLED }),
          Device.new('2', { name: 'NAME2', udid: 'UDID2', platform: Platform::IOS, status: Device::Status::ENABLED }),
          Device.new('3', { name: 'NEW_NAME3', udid: 'UDID3', platform: Platform::MAC_OS, status: Device::Status::DISABLED }),
          Device.new('4', { name: 'NEW_NAME4', udid: 'UDID4', platform: Platform::MAC_OS, status: Device::Status::ENABLED }),
          Device.new('5', { name: 'NAME5', udid: 'UDID5', platform: Platform::IOS, status: Device::Status::ENABLED })
        ]

        it 'outputs dry run log' do
          stub_const('ENV', { 'DEBUG' => '1' })
          allow(Time).to receive(:now).and_return Time.new(2024, 1, 2, 15, 4, 5)
          expected_message = <<~LOG
          [15:04:05]: (dry-run) Skipped NAME0 (UDID0)
          [15:04:05]: (dry-run) Disabled NAME1 (UDID1)
          [15:04:05]: (dry-run) Enabled NAME2 (UDID2)
          [15:04:05]: (dry-run) Disabled and renamed from NAME3 to NEW_NAME3 (UDID3)
          [15:04:05]: (dry-run) Renamed from NAME4 to NEW_NAME4 (UDID4)
          [15:04:05]: (dry-run) Created NAME5 (UDID5)
          LOG

          patch = described_class.new(old_devices, new_devices)
          expect { patch.apply!(dry_run: true) }.to output(expected_message).to_stdout
        end
      end

      context 'when new devices change platform' do
        old_devices = [
          Device.new('0', { name: 'NAME0', udid: 'UDID0', platform: Platform::IOS, status: Device::Status::ENABLED })
        ]
        new_devices = [
          Device.new('0', { name: 'NAME0', udid: 'UDID0', platform: Platform::MAC_OS, status: Device::Status::ENABLED })
        ]

        it 'raises an error' do
          expect { described_class.new(old_devices, new_devices) }.to raise_error UnsupportedOperation
        end
      end

      context 'when an error occurred while creating a device' do
        old_devices = []
        new_devices = [
          Device.new('0', { name: 'NAME0', udid: 'UDID0', platform: Platform::IOS, status: Device::Status::ENABLED })
        ]

        before do
          allow(Device).to receive(:create).and_raise Spaceship::UnexpectedResponse
        end

        it 'raises the error' do
          patch = described_class.new(old_devices, new_devices)
          expect { patch.apply! }.to raise_error Spaceship::UnexpectedResponse
        end
      end
    end
  end
end
