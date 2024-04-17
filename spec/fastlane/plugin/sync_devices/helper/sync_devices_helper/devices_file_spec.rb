# frozen_string_literal: true

require 'cfpropertylist'
require 'spaceship'
require 'json'
require 'tempfile'

describe Fastlane::Helper::SyncDevicesHelper::DevicesFile do
  include FixtureHelper

  describe '.load' do
    before do
      allow(described_class).to receive(:load).and_call_original
      allow(described_class).to receive(:load_tsv)
      allow(described_class).to receive(:load_plist)
    end

    %w[.txt .tsv].each do |ext|
      context "with a file#{ext}" do
        let(:path) { "file#{ext}" }

        it 'treats the file as TSV' do
          described_class.load(path)
          expect(described_class).to have_received(:load_tsv).with(path).once
        end
      end
    end

    %w[.deviceids .plist .xml].each do |ext|
      context "with a file#{ext}" do
        let(:path) { "file#{ext}" }

        it 'treats the file as Property List' do
          described_class.load(path)
          expect(described_class).to have_received(:load_plist).with(path).once
        end
      end
    end

    context 'when a file with unknown extension and its contents is TSV' do
      let(:contents) do
        <<~TSV
          Device ID	Device Name	Device Platform
          01234567-89ABCDEF01234567	NAME1	ios
        TSV
      end

      it 'treats the file as TSV' do
        Tempfile.open do |f|
          f.write(contents)
          f.rewind

          described_class.load(f.path)
          expect(described_class).to have_received(:load_tsv).with(f.path).once
        end
      end
    end

    context 'when a file with unknown extension and its contents is Property List' do
      let(:contents) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>Device UDIDs</key>
            <array>
              <dict>
                <key>deviceIdentifier</key>
                <string>01234567-89ABCDEF01234567</string>
                <key>deviceName</key>
                <string>NAME1</string>
                <key>devicePlatform</key>
                <string>ios</string>
              </dict>
            </array>
          </dict>
          </plist>
        XML
      end

      it 'treats the file as TSV' do
        Tempfile.open do |f|
          f.write(contents)
          f.rewind

          described_class.load(f.path)
          expect(described_class).to have_received(:load_tsv).with(f.path).once
        end
      end
    end
  end

  describe '.load_tsv' do
    context 'with an empty file' do
      it 'raises an error' do
        Tempfile.open do |f|
          expect { described_class.load_tsv(f.path) }.to raise_error(
            Fastlane::Helper::SyncDevicesHelper::InvalidDevicesFile,
            /^Invalid header line at/
          )
        end
      end
    end

    context 'with a valid file' do
      let(:path) { fixture('multiple-device-upload.txt') }

      it 'returns devices' do
        devices = described_class.load_tsv(path)
        # Since Spaceship::ConnectAPI::Device cannot be compared with each other,
        # convert them into Hash via JSON.
        expect(JSON.parse(devices.to_json)).to eq JSON.parse(File.read(fixture('devices.json')))
      end
    end

    context 'with /dev/fd/N' do
      # rubocop:disable RSpec/InstanceVariable
      before { @reader, @writer = IO.pipe }

      after { @reader.close }

      it 'returns devices' do
        @writer.puts("Device ID\tDevice Name\tDevice Platform\n")
        @writer.close
        devices = described_class.load_tsv("/dev/fd/#{@reader.fileno}")
        expect(devices).to be_empty
      end
      # rubocop:enable RSpec/InstanceVariable
    end

    context 'with a valid IO object' do
      let(:path) { fixture('multiple-device-upload.txt') }

      it 'returns devices' do
        devices = File.open(path, 'rb') { |f| described_class.load_tsv(f) }
        # Since Spaceship::ConnectAPI::Device cannot be compared with each other,
        # convert them into Hash via JSON.
        expect(JSON.parse(devices.to_json)).to eq JSON.parse(File.read(fixture('devices.json')))
      end
    end

    context 'when the file has extra headers' do
      let(:contents) do
        <<~TSV
          Device ID	Device Name	Device Platform	Extra
        TSV
      end

      it 'raises an error' do
        Tempfile.open do |f|
          f.write(contents)
          f.rewind

          expect { described_class.load_tsv(f.path) }.to raise_error(
            Fastlane::Helper::SyncDevicesHelper::InvalidDevicesFile,
            /^Invalid header/
          )
        end
      end
    end

    context 'with the file does not have `Device Platform` header' do
      let(:contents) do
        <<~TSV
          Device ID	Device Name
          01234567-89ABCDEF01234567	NAME1
        TSV
      end

      it 'assumes all devices are iOS' do
        Tempfile.open do |f|
          f.write(contents)
          f.rewind

          expect(described_class.load_tsv(f.path)).to contain_exactly(
            an_object_having_attributes(platform: Spaceship::ConnectAPI::BundleIdPlatform::IOS)
          )
        end
      end
    end

    context 'when a file has extra columns' do
      let(:contents) do
        <<~TSV
          Device ID	Device Name	Device Platform
          01234567-89ABCDEF01234567	NAME1	ios	extra
        TSV
      end

      it 'raises an error' do
        Tempfile.open do |f|
          f.write(contents)
          f.rewind

          expect { described_class.load_tsv(f.path) }.to raise_error(
            Fastlane::Helper::SyncDevicesHelper::InvalidDevicesFile,
            /^Invalid device line at .+:2/
          )
        end
      end
    end

    context 'when a file has missing columns' do
      let(:contents) do
        <<~TSV
          Device ID	Device Name	Device Platform
          01234567-89ABCDEF01234567
        TSV
      end

      it 'raises an error' do
        Tempfile.open do |f|
          f.write(contents)
          f.rewind

          expect { described_class.load_tsv(f.path) }.to raise_error(
            Fastlane::Helper::SyncDevicesHelper::InvalidDevicesFile,
            /^Invalid device line at .+:2/
          )
        end
      end
    end

    context 'with a device whose UDID has missing hyphen' do
      let(:contents) do
        <<~TSV
          Device ID	Device Name	Device Platform
          0123456789ABCDEF01234567	NAME1	ios
        TSV
      end

      it 'raises an error' do
        Tempfile.open do |f|
          f.write(contents)
          f.rewind

          expect { described_class.load_tsv(f.path) }.to raise_error(
            Fastlane::Helper::SyncDevicesHelper::InvalidDevicesFile,
            /^Invalid UDID/
          )
        end
      end
    end

    context 'with a device whose UDID is not unique' do
      let(:contents) do
        <<~TSV
          Device ID	Device Name	Device Platform
          01234567-89ABCDEF01234567	NAME1	ios
          01234567-89ABCDEF01234567	NAME2	ios
        TSV
      end

      it 'raises an error' do
        Tempfile.open do |f|
          f.write(contents)
          f.rewind

          expect { described_class.load_tsv(f.path) }.to raise_error(
            Fastlane::Helper::SyncDevicesHelper::InvalidDevicesFile,
            /^Invalid UDID.+another device with the same UDID is defined$/
          )
        end
      end
    end

    context 'with a device whose name is 51+ characters long' do
      let(:contents) do
        long_name = 'A' * 51
        <<~TSV
          Device ID	Device Name	Device Platform
          01234567-89ABCDEF01234567	#{long_name}	ios
        TSV
      end

      it 'raises an error' do
        Tempfile.open do |f|
          f.write(contents)
          f.rewind

          expect { described_class.load_tsv(f.path) }.to raise_error(
            Fastlane::Helper::SyncDevicesHelper::InvalidDevicesFile,
            /^Invalid device name.+must be less than or equal to 50 characters long$/
          )
        end
      end
    end

    context 'with a device of tvOS platform' do
      let(:contents) do
        <<~TSV
          Device ID	Device Name	Device Platform
          01234567-89ABCDEF01234567	NAME1	tvos
        TSV
      end

      it 'raises an error' do
        Tempfile.open do |f|
          f.write(contents)
          f.rewind

          expect { described_class.load_tsv(f.path) }.to raise_error(
            Fastlane::Helper::SyncDevicesHelper::InvalidDevicesFile,
            /^Unknown platform 'tvos' at/
          )
        end
      end
    end

    context 'with a device of watchOS platform' do
      let(:contents) do
        <<~TSV
          Device ID	Device Name	Device Platform
          01234567-89ABCDEF01234567	NAME1	watchos
        TSV
      end

      it 'raises an error' do
        Tempfile.open do |f|
          f.write(contents)
          f.rewind

          expect { described_class.load_tsv(f.path) }.to raise_error(
            Fastlane::Helper::SyncDevicesHelper::InvalidDevicesFile,
            /^Unknown platform/
          )
        end
      end
    end

    context 'with a device of unknown platform' do
      let(:contents) do
        <<~TSV
          Device ID	Device Name	Device Platform
          01234567-89ABCDEF01234567	NAME1	unknown
        TSV
      end

      it 'raises an error' do
        Tempfile.open do |f|
          f.write(contents)
          f.rewind

          expect { described_class.load_tsv(f.path) }.to raise_error(
            Fastlane::Helper::SyncDevicesHelper::InvalidDevicesFile,
            /^Unknown platform/
          )
        end
      end
    end
  end

  describe '.load_plist' do
    context 'with an empty file' do
      it 'raises an error' do
        Tempfile.open do |f|
          expect { described_class.load_plist(f.path) }.to raise_error(IOError, /is empty/)
        end
      end
    end

    context 'with a valid XML PropertyList file' do
      let(:path) { fixture('multiple-device-upload.deviceids') }

      it 'returns devices' do
        devices = described_class.load_plist(path)
        expect(JSON.parse(devices.to_json)).to eq JSON.parse(File.read(fixture('devices.json')))
      end
    end

    context 'with a valid NeXT Step PropertyList file' do
      let(:path) { fixture('multiple-device-upload.next-step.plist') }

      it 'returns devices' do
        Tempfile.open do |tmp|
          # Remove the last newlines.
          # This is a workaround to avoid https://github.com/ckruse/CFPropertyList/issues/67
          tmp.write(File.read(path).chomp)
          tmp.rewind

          devices = described_class.load_plist(tmp.path)
          expect(JSON.parse(devices.to_json)).to eq JSON.parse(File.read(fixture('devices.json')))
        end
      end
    end

    context 'when the file does not have `devicePlatform` key' do
      let(:contents) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>Device UDIDs</key>
            <array>
              <dict>
                <key>deviceIdentifier</key>
                <string>01234567-89ABCDEF01234567</string>
                <key>deviceName</key>
                <string>NAME1</string>
              </dict>
            </array>
          </dict>
          </plist>
        XML
      end

      it 'assumes all devices are iOS' do
        Tempfile.open do |f|
          f.write(contents)
          f.rewind

          expect(described_class.load_plist(f.path)).to contain_exactly(
            an_object_having_attributes(platform: Spaceship::ConnectAPI::BundleIdPlatform::IOS)
          )
        end
      end
    end

    context 'when the file does not have `deviceName` key' do
      let(:contents) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>Device UDIDs</key>
            <array>
              <dict>
                <key>deviceIdentifier</key>
                <string>01234567-89ABCDEF01234567</string>
                <key>devicePlatform</key>
                <string>ios</string>
              </dict>
            </array>
          </dict>
          </plist>
        XML
      end

      it 'returns devices' do
        Tempfile.open do |f|
          f.write(contents)
          f.rewind

          expect { described_class.load_plist(f.path) }.to raise_error(
            Fastlane::Helper::SyncDevicesHelper::InvalidDevicesFile,
            /^Invalid device file/
          )
        end
      end
    end

    context 'when the file does not have `deviceIdentifier` key' do
      let(:contents) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>Device UDIDs</key>
            <array>
              <dict>
                <key>deviceIdentifier</key>
                <string>01234567-89ABCDEF01234567</string>
              </dict>
            </array>
          </dict>
          </plist>
        XML
      end

      it 'raises an error' do
        Tempfile.open do |f|
          f.write(contents)
          f.rewind

          expect { described_class.load_plist(f.path) }.to raise_error(
            Fastlane::Helper::SyncDevicesHelper::InvalidDevicesFile,
            /^Invalid device file/
          )
        end
      end
    end
  end

  describe '.dump' do
    let(:devices) { [] }
    let(:path) { '/path/to/file' }

    before do
      allow(described_class).to receive(:dump).and_call_original
      allow(described_class).to receive(:dump_tsv)
      allow(described_class).to receive(:dump_plist)
    end

    context 'with format: :tsv' do
      it 'delegates to dump_tsv()' do
        described_class.dump(devices, path, format: :tsv)
        expect(described_class).to have_received(:dump_tsv).with(devices, path)
      end
    end

    context 'with format: :plist' do
      it 'delegates to dump_plist()' do
        described_class.dump(devices, path, format: :plist)
        expect(described_class).to have_received(:dump_plist).with(devices, path)
      end
    end

    context 'with invalid format' do
      it 'raises an error' do
        expect { described_class.dump(devices, path, format: :invalid) }.to raise_error(
          RuntimeError,
          /Unsupported format/
        )
      end
    end
  end

  describe '.dump_tsv' do
    context 'with no devices' do
      it 'writes only headers' do
        Tempfile.open do |f|
          described_class.dump_tsv([], f.path)
          f.rewind
          expect(f.read).to eq "Device ID\tDevice Name\tDevice Platform\n"
        end
      end
    end

    context 'with devices' do
      let(:devices) do
        [
          Spaceship::ConnectAPI::Device.new(
            nil,
            {
              name: 'NAME',
              udid: 'UDID',
              platform: 'IOS',
              status: 'ENABLED'
            }
          )
        ]
      end

      it 'writes rows after headers' do
        Tempfile.open do |f|
          described_class.dump_tsv(devices, f.path)
          f.rewind
          expect(f.read).to eq <<~TSV
            Device ID\tDevice Name\tDevice Platform
            UDID\tNAME\tIOS
          TSV
        end
      end
    end
  end

  describe '.dump_plist' do
    context 'with no devices' do
      it 'writes only headers' do
        Tempfile.open do |f|
          described_class.dump_plist([], f.path)
          f.rewind
          plist = CFPropertyList::List.new(file: f.path)
          data = CFPropertyList.native_types(plist.value)
          expect(data).to eq({ 'Device UDIDs' => [] })
        end
      end
    end

    context 'with devices' do
      let(:devices) do
        [
          Spaceship::ConnectAPI::Device.new(
            nil,
            {
              name: 'NAME',
              udid: 'UDID',
              platform: 'IOS',
              status: 'ENABLED'
            }
          )
        ]
      end

      let(:expected_data) do
        {
          'Device UDIDs' => [
            {
              'deviceIdentifier' => 'UDID',
              'deviceName' => 'NAME',
              'devicePlatform' => 'ios'
            }
          ]
        }
      end

      it 'writes rows after headers' do
        Tempfile.open do |f|
          described_class.dump_plist(devices, f.path)
          f.rewind
          plist = CFPropertyList::List.new(file: f.path)
          data = CFPropertyList.native_types(plist.value)
          expect(data).to eq expected_data
        end
      end
    end
  end
end
