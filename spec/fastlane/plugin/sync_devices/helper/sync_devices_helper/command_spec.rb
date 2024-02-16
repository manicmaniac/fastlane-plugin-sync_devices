module Fastlane::Helper::SyncDevicesHelper::Command
  device = Spaceship::ConnectAPI::Device.new('ID', {
    name: 'NAME',
    udid: 'UDID',
    platform: Spaceship::ConnectAPI::Platform::IOS
  })

  describe Noop do
    describe '#run' do
      it 'does nothing' do
        allow(Spaceship::ConnectAPI::Client).to receive(:new)

        described_class.new(device).run

        expect(Spaceship::ConnectAPI::Client).not_to have_received(:new)
      end
    end

    describe '#description' do
      it 'returns description' do
        expect(described_class.new(device).description).to eq 'Skipped NAME (UDID)'
      end
    end
  end

  describe Disable do
    describe '#run' do
      it 'disables the device' do
        allow(Spaceship::ConnectAPI::Device).to receive(:disable)

        described_class.new(device).run

        expect(Spaceship::ConnectAPI::Device).to have_received(:disable).with('UDID').once
      end
    end

    describe '#description' do
      it 'returns description' do
        expect(described_class.new(device).description).to eq 'Disabled NAME (UDID)'
      end
    end
  end

  describe Modify do
    describe '#run' do
      let(:new_device) do
        Spaceship::ConnectAPI::Device.new(nil, {
          name: 'NEW_NAME',
          udid: 'UDID',
          status: Spaceship::ConnectAPI::Device::Status::DISABLED
        })
      end

      it 'modifies the device' do
        allow(Spaceship::ConnectAPI::Device).to receive(:modify)

        described_class.new(device, new_device).run

        expect(Spaceship::ConnectAPI::Device).to have_received(:modify)
          .with('UDID', enabled: false, new_name: 'NEW_NAME')
          .once
      end
    end

    describe '#description' do
      subject { described_class.new(device, new_device).description }

      context 'when disabled and renamed' do
        let(:new_device) do
          device.dup.tap do |d|
            d.status = Spaceship::ConnectAPI::Device::Status::DISABLED
            d.name = 'NEW_NAME'
          end
        end

        it { is_expected.to eq 'Disabled and renamed from NAME to NEW_NAME (UDID)' }
      end

      context 'when enabled' do
        let(:new_device) do
          device.dup.tap do |d|
            d.status = Spaceship::ConnectAPI::Device::Status::ENABLED
          end
        end

        it { is_expected.to eq 'Enabled NAME (UDID)' }
      end

      context 'when enabled and renamed' do
        let(:new_device) do
          device.dup.tap do |d|
            d.status = Spaceship::ConnectAPI::Device::Status::ENABLED
            d.name = 'NEW_NAME'
          end
        end

        it { is_expected.to eq 'Enabled and renamed from NAME to NEW_NAME (UDID)' }
      end

      context 'when renamed' do
        let(:new_device) do
          device.dup.tap do |d|
            d.name = 'NEW_NAME'
          end
        end

        it { is_expected.to eq 'Renamed from NAME to NEW_NAME (UDID)' }
      end
    end
  end

  describe Create do
    describe '#run' do
      it 'creates the device' do
        allow(Spaceship::ConnectAPI::Device).to receive(:create)

        described_class.new(device).run

        expect(Spaceship::ConnectAPI::Device).to have_received(:create)
          .with(name: 'NAME', platform: Spaceship::ConnectAPI::Platform::IOS, udid: 'UDID')
      end
    end

    describe '#description' do
      it 'returns description' do
        expect(described_class.new(device).description).to eq 'Created NAME (UDID)'
      end
    end
  end
end
