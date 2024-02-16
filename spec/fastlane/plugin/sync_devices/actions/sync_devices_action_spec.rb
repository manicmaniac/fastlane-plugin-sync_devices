describe Fastlane::Actions::SyncDevicesAction do
  include FixtureHelper

  describe '.run' do
    context 'without `devices_file` option' do
      it 'raises an error' do
        expect { described_class.run({}) }.to raise_error FastlaneCore::Interface::FastlaneError
      end
    end

    context 'with invalid credentials' do
      let(:account_manager) do
        instance_double(CredentialsManager::AccountManager, {
          user: 'USER',
          password: 'PASSWORD'
        })
      end
      let(:devices_file) { fixture('multiple-device-upload.txt') }

      before do
        allow(FastlaneCore::UI).to receive(:message)
        allow(CredentialsManager::AccountManager).to receive(:new).and_return account_manager
        allow(Spaceship::ConnectAPI).to receive(:login).and_raise Spaceship::AccessForbiddenError
      end

      it 'raises an error' do
        expect { described_class.run({ devices_file: devices_file }) }.to raise_error Spaceship::AccessForbiddenError
        expect(FastlaneCore::UI).to have_received(:message).with(a_string_matching(/Login/)).once
      end
    end

    context 'with valid credentials' do
      let(:account_manager) do
        instance_double(CredentialsManager::AccountManager, {
          user: 'USER',
          password: 'PASSWORD'
        })
      end
      let(:devices_file) { fixture('multiple-device-upload.txt') }

      before do
        allow(FastlaneCore::UI).to receive(:message)
        allow(FastlaneCore::UI).to receive(:success)
        allow(CredentialsManager::AccountManager).to receive(:new).and_return account_manager
        allow(Spaceship::ConnectAPI).to receive(:login)
        allow(Spaceship::ConnectAPI::Device).to receive(:all).and_return []
        allow(Spaceship::ConnectAPI::Device).to receive(:create)
        allow(Spaceship::ConnectAPI::Device).to receive(:modify)
      end

      it 'updates devices' do
        described_class.run({ devices_file: devices_file })
        called_count = 0
        expect(Spaceship::ConnectAPI::Device).to have_received(:create).exactly(4).times
        expect(Spaceship::ConnectAPI::Device).not_to have_received(:modify)
      end
    end
  end

  describe '.description' do
    it 'returns description' do
      expect(described_class.description).to be_a(String)
    end
  end

  describe '.authors' do
    it 'returns authors' do
      expect(described_class.authors).to contain_exactly(kind_of(String))
    end
  end

  describe '.details' do
    it 'returns details' do
      expect(described_class.details).to be_a(String)
    end
  end

  describe '.available_options' do
    it 'returns available options' do
      expect(described_class.available_options).to match_array [kind_of(FastlaneCore::ConfigItem)] * 7
    end
  end

  describe '.is_supported?' do
    Fastlane::SupportedPlatforms.all.each do |platform|
      it "returns true for #{platform}" do
        expect(described_class.is_supported?(platform)).to be true
      end
    end
  end

  describe '.example_code' do
    it 'returns example codes' do
      expect(described_class.example_code).to match_array [kind_of(String)] * 3
    end
  end

  describe '.category' do
    it 'returns `code_signing` category' do
      expect(described_class.category).to eq :code_signing
    end
  end
end
