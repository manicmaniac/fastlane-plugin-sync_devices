module Fastlane::Helper::SyncDevicesHelper::Command
  describe Noop do
    let(:device) do
      Spaceship::ConnectAPI::Device.new('ID', {
        name: 'NAME',
        udid: 'UDID',
        platform: Spaceship::ConnectAPI::Platform::IOS,
        status: Spaceship::ConnectAPI::Device::Status::ENABLED
      })
    end

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
    let(:device) do
      Spaceship::ConnectAPI::Device.new('ID', {
        name: 'NAME',
        udid: 'UDID',
        platform: Spaceship::ConnectAPI::Platform::IOS,
        status: Spaceship::ConnectAPI::Device::Status::ENABLED
      })
    end

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

  describe Enable do
    let(:device) do
      Spaceship::ConnectAPI::Device.new('ID', {
        name: 'NAME',
        udid: 'UDID',
        platform: Spaceship::ConnectAPI::Platform::IOS,
        status: Spaceship::ConnectAPI::Device::Status::DISABLED
      })
    end

    describe '#run' do
      it 'enables the device' do
        allow(Spaceship::ConnectAPI::Device).to receive(:enable)

        described_class.new(device).run

        expect(Spaceship::ConnectAPI::Device).to have_received(:enable).with('UDID').once
      end
    end

    describe '#description' do
      it 'returns description' do
        expect(described_class.new(device).description).to eq 'Enabled NAME (UDID)'
      end
    end
  end

  describe Rename do
    let(:device) do
      Spaceship::ConnectAPI::Device.new('ID', {
        name: 'NAME',
        udid: 'UDID',
        platform: Spaceship::ConnectAPI::Platform::IOS,
        status: Spaceship::ConnectAPI::Device::Status::ENABLED
      })
    end

    describe '#run' do
      it 'renames the device' do
        allow(Spaceship::ConnectAPI::Device).to receive(:rename)

        described_class.new(device, 'NEW_NAME').run

        expect(Spaceship::ConnectAPI::Device).to have_received(:rename).with('UDID', 'NEW_NAME').once
      end
    end

    describe '#description' do
      it 'returns description' do
        expect(described_class.new(device, 'NEW_NAME').description).to eq 'Renamed NAME to NEW_NAME (UDID)'
      end
    end
  end

  describe DisableAndRename do
    let(:device) do
      Spaceship::ConnectAPI::Device.new('ID', {
        name: 'NAME',
        udid: 'UDID',
        platform: Spaceship::ConnectAPI::Platform::IOS,
        status: Spaceship::ConnectAPI::Device::Status::ENABLED
      })
    end

    describe '#run' do
      it 'disables and renames the device' do
        allow(Spaceship::ConnectAPI::Device).to receive(:modify)

        described_class.new(device, 'NEW_NAME').run

        expect(Spaceship::ConnectAPI::Device).to have_received(:modify).with('UDID', enabled: false, new_name: 'NEW_NAME').once
      end
    end

    describe '#description' do
      it 'returns description' do
        expect(described_class.new(device, 'NEW_NAME').description).to eq 'Disabled and renamed NAME to NEW_NAME (UDID)'
      end
    end
  end

  describe EnableAndRename do
    let(:device) do
      Spaceship::ConnectAPI::Device.new('ID', {
        name: 'NAME',
        udid: 'UDID',
        platform: Spaceship::ConnectAPI::Platform::IOS,
        status: Spaceship::ConnectAPI::Device::Status::DISABLED
      })
    end

    describe '#run' do
      it 'enables and renames the device' do
        allow(Spaceship::ConnectAPI::Device).to receive(:modify)

        described_class.new(device, 'NEW_NAME').run

        expect(Spaceship::ConnectAPI::Device).to have_received(:modify)
          .with('UDID', enabled: true, new_name: 'NEW_NAME').once
      end
    end

    describe '#description' do
      it 'returns description' do
        expect(described_class.new(device, 'NEW_NAME').description).to eq 'Enabled and renamed NAME to NEW_NAME (UDID)'
      end
    end
  end

  describe Create do
    let(:device) do
      Spaceship::ConnectAPI::Device.new('ID', {
        name: 'NAME',
        udid: 'UDID',
        platform: Spaceship::ConnectAPI::Platform::IOS,
        status: Spaceship::ConnectAPI::Device::Status::ENABLED
      })
    end

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
