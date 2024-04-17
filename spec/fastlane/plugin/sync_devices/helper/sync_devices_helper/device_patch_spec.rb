# frozen_string_literal: true

describe Fastlane::Helper::SyncDevicesHelper::DevicePatch do
  device = Spaceship::ConnectAPI::Device.new(
    nil,
    {
      name: 'NAME',
      udid: 'UDID',
      platform: Spaceship::ConnectAPI::BundleIdPlatform::IOS,
      status: Spaceship::ConnectAPI::Device::Status::ENABLED
    }
  )

  describe '#renamed?' do
    subject { described_class.new(old_device, new_device).renamed? }

    [
      ['when renamed', 'OLD_NAME', 'NEW_NAME', true],
      ['when not renamed', 'OLD_NAME', 'OLD_NAME', false],
      ['without old device', nil, 'NEW_NAME', false],
      ['without new device', 'OLD_NAME', nil, false]
    ].each do |condition, old_name, new_name, expected_value|
      context(condition) do
        let(:old_device) { device.dup.tap { |d| d.name = old_name } if old_name }
        let(:new_device) { device.dup.tap { |d| d.name = new_name } if new_name }

        it { is_expected.to be expected_value }
      end
    end
  end

  describe '#enabled?' do
    subject { described_class.new(old_device, new_device).enabled? }

    disabled = Spaceship::ConnectAPI::Device::Status::DISABLED
    enabled = Spaceship::ConnectAPI::Device::Status::ENABLED

    [
      ['when the status is changed from disabled to enabled', disabled, enabled, true],
      ['when the status is changed from enabled to disabled', enabled, disabled, false],
      ['when the status is not changed from disabled', disabled, disabled, false],
      ['when the status is not changed from enabled', enabled, enabled, false],
      ['when the old device is nil', nil, enabled, false],
      ['when the new device is nil', disabled, nil, false]
    ].each do |condition, old_status, new_status, expected_value|
      context(condition) do
        let(:old_device) { device.dup.tap { |d| d.status = old_status } if old_status }
        let(:new_device) { device.dup.tap { |d| d.status = new_status } if new_status }

        it { is_expected.to be expected_value }
      end
    end
  end

  describe '#disabled?' do
    subject { described_class.new(old_device, new_device).disabled? }

    disabled = Spaceship::ConnectAPI::Device::Status::DISABLED
    enabled = Spaceship::ConnectAPI::Device::Status::ENABLED

    [
      ['when the status is changed from enabled to disabled', enabled, disabled, true],
      ['when the status is changed from disabled to enabled', disabled, enabled, false],
      ['when the status is not changed from disabled', disabled, disabled, false],
      ['when the status is not changed from enabled', enabled, enabled, false],
      ['when the old device is nil', nil, disabled, false],
      ['when the new device is nil', enabled, nil, true]
    ].each do |condition, old_status, new_status, expected_value|
      context(condition) do
        let(:old_device) { device.dup.tap { |d| d.status = old_status } if old_status }
        let(:new_device) { device.dup.tap { |d| d.status = new_status } if new_status }

        it { is_expected.to be expected_value }
      end
    end
  end

  describe '#created?' do
    subject { described_class.new(old_device, new_device).created? }

    disabled = Spaceship::ConnectAPI::Device::Status::DISABLED
    enabled = Spaceship::ConnectAPI::Device::Status::ENABLED

    [
      ['when the status is changed from disabled to enabled', disabled, enabled, false],
      ['when the status is changed from enabled to disabled', enabled, disabled, false],
      ['when the status is not changed from disabled', disabled, disabled, false],
      ['when the status is not changed from enabled', enabled, enabled, false],
      ['when the old device is nil and the new device is disabled', nil, disabled, false],
      ['when the old device is nil and the new device is enabled', nil, enabled, true],
      ['when the new device is nil', enabled, nil, false]
    ].each do |condition, old_status, new_status, expected_value|
      context(condition) do
        let(:old_device) { device.dup.tap { |d| d.status = old_status } if old_status }
        let(:new_device) { device.dup.tap { |d| d.status = new_status } if new_status }

        it { is_expected.to be expected_value }
      end
    end
  end

  describe '#platform_changed?' do
    subject { described_class.new(old_device, new_device).platform_changed? }

    ios = Spaceship::ConnectAPI::BundleIdPlatform::IOS
    mac_os = Spaceship::ConnectAPI::BundleIdPlatform::MAC_OS

    [
      ['when the platform is changed from iOS to macOS', ios, mac_os, true],
      ['when the platform is changed from macOS to iOS', mac_os, ios, true],
      ['when the platform is not changed from iOS', ios, ios, false],
      ['when the platform is not changed from macOS', mac_os, mac_os, false],
      ['when the old device is nil', nil, mac_os, false],
      ['when the new device is nil', ios, nil, false]
    ].each do |condition, old_platform, new_platform, expected_value|
      context(condition) do
        let(:old_device) { device.dup.tap { |d| d.platform = old_platform } if old_platform }
        let(:new_device) { device.dup.tap { |d| d.platform = new_platform } if new_platform }

        it { is_expected.to be expected_value }
      end
    end
  end

  describe '#command' do
    subject(:get_command) { described_class.new(old_device, new_device).command }

    command = Fastlane::Helper::SyncDevicesHelper::Command
    disabled = Spaceship::ConnectAPI::Device::Status::DISABLED

    [
      ['when the old and new devices are identical', device.dup, device.dup, command::Noop],
      ['when the new device is created', nil, device.dup, command::Create],
      ['when the new device is nil', device.dup, nil, command::Disable],
      [
        'when the status is changed from disabled to enabled',
        device.dup.tap { |d| d.status = disabled }, device.dup, command::Enable
      ],
      [
        'when the name is changed',
        device.dup, device.dup.tap { |d| d.name = 'NEW_NAME' }, command::Rename
      ],
      [
        'when the new device is disabled and renamed',
        device.dup,
        device.dup.tap do |d|
          d.status = disabled
          d.name = 'NEW_NAME'
        end,
        command::DisableAndRename
      ],
      [
        'when the new device is enabled and renamed',
        device.dup.tap { |d| d.status = disabled }, device.dup.tap { |d| d.name = 'NEW_NAME' }, command::EnableAndRename
      ]
    ].each do |condition, old, new, expected_class|
      context(condition) do
        let(:old_device) { old }
        let(:new_device) { new }

        it { is_expected.to be_an expected_class }
      end
    end

    context 'when the platform is changed' do
      let(:old_device) { device.dup }
      let(:new_device) { device.dup.tap { |d| d.platform = Spaceship::ConnectAPI::BundleIdPlatform::MAC_OS } }

      example do
        expect { get_command }.to raise_error(
          Fastlane::Helper::SyncDevicesHelper::UnsupportedOperation,
          /Cannot change platform/
        )
      end
    end

    context 'when randomly changes the devices with the consistent platform' do
      names = %w[OLD_NAME NEW_NAME]
      statuses = [
        Spaceship::ConnectAPI::Device::Status::ENABLED,
        Spaceship::ConnectAPI::Device::Status::DISABLED
      ]

      devices = [nil] + names.product(statuses).map do |name, status|
        device.dup.tap do |d|
          d.name = name
          d.status = status
        end
      end

      device_pairs = devices.product(devices)

      it 'never raises an error' do
        expect do
          device_pairs.each do |old_device, new_device|
            described_class.new(old_device, new_device).command
          end
        end.not_to raise_error
      end
    end
  end
end
