# frozen_string_literal: true

require 'csv'
require 'json'
require 'open-uri'
require 'openssl'
require 'spaceship'
require 'timeout'

describe 'fastlane-plugin-sync_devices' do
  include CommandLineHelper
  include DeviceHelper
  include FixtureHelper

  let(:fastlane_path) { Gem.bin_path('fastlane', 'fastlane') }
  let(:env) do
    {
      'CI' => '1', # To make fastlane non-interactive
      'NO_COLOR' => '1',
      'FASTLANE_HIDE_CHANGELOG' => '1',
      'FASTLANE_HIDE_GITHUB_ISSUES' => '1',
      'FASTLANE_HIDE_PLUGINS_TABLE' => '1',
      'FASTLANE_HIDE_TIMESTAMP' => '1',
      'FASTLANE_SKIP_UPDATE_CHECK' => '1',
      'FL_SYNC_DEVICES_API_KEY_PATH' => fixture('api_key.json'),
      'SPACESHIP_DEBUG' => '1' # Set https://127.0.0.1:8888 as proxy and skip SSL verification
    }
  end

  describe 'fastlane action sync_devices' do
    it 'prints help' do
      expect { system_ruby(env, fastlane_path, 'action', 'sync_devices', exception: true) }
        .to output(/sync_devices/)
        .to_stdout_from_any_process
        .and output('')
        .to_stderr_from_any_process
    end
  end

  describe 'fastlane run sync_devices' do
    it 'fails with error messages' do
      aggregate_failures do
        expect { system_ruby(env, fastlane_path, 'run', 'sync_devices') }
          .to output(/sync_devices/)
          .to_stdout_from_any_process
          .and output(/You must pass `devices_file`/)
          .to_stderr_from_any_process
        expect(Process.last_status).not_to be_success
      end
    end
  end

  describe 'fastlane run sync_devices devices_file:/path/to/devices.tsv' do
    around do |example|
      IO.pipe do |reader, writer|
        pid = spawn_ruby({}, File.expand_path('../support/servers/proxy.rb', __dir__), err: writer)
        at_exit { Process.kill('INT', pid) } # In case rspec suddenly dies before cleanup
        Timeout.timeout(10) do
          sleep(0.1) until reader.readline.include?('#start')
        end
        example.run
        Process.kill('INT', pid)
        writer.close
        IO.copy_stream(reader, $stderr) if example.exception
      end
    end

    context 'when adding, deleting and renaming random devices' do
      let(:enabled_device_udids) do
        CSV.read(fixture('system/1.tsv'), headers: true, col_sep: "\t")
           .map { |row| row['Device ID'] }
           .sort
      end

      it 'synchronizes remote devices with local devices file' do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
        Timeout.timeout(30) do
          aggregate_failures 'create initial devices' do
            expect do
              system_ruby(env, fastlane_path, 'run', 'sync_devices', "devices_file:#{fixture('system/0.tsv')}",
                          exception: true)
            end
              .to output(/(Created.+){10}.+Successfully synchronized devices/m)
              .to_stdout_from_any_process
              .and output('')
              .to_stderr_from_any_process
          end
          aggregate_failures 'update devices' do
            expect do
              system_ruby(env, fastlane_path, 'run', 'sync_devices', "devices_file:#{fixture('system/1.tsv')}",
                          exception: true)
            end
              .to output(/Successfully synchronized devices/)
              .to_stdout_from_any_process
              .and output('')
              .to_stderr_from_any_process
          end
          aggregate_failures 'check if devices are registered as expected' do
            actual_devices = URI.open('https://localhost:4567/v1/devices', ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
                                .read
                                .then { |data| JSON.parse(data) }
                                .then { |json| Spaceship::ConnectAPI::Models.parse(json) }
            expect(actual_devices.size).to eq 28
            expect(actual_devices.select(&:enabled?).map(&:udid).sort).to eq enabled_device_udids
          end
        end
      end
    end
  end
end
