# frozen_string_literal: true

require 'json'
require 'open-uri'
require 'openssl'
require 'spaceship'
require 'timeout'

describe 'fastlane-plugin-sync_devices' do
  include DeviceHelper
  include FixtureHelper

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
      expect { system(env, 'fastlane action sync_devices', exception: true) }
        .to output(/sync_devices/)
        .to_stdout_from_any_process
        .and output('')
        .to_stderr_from_any_process
    end
  end

  describe 'fastlane run sync_devices' do
    context 'without arguments' do
      it 'fails with error messages' do
        expect { system(env, 'fastlane run sync_devices') }
          .to output(/sync_devices/)
          .to_stdout_from_any_process
          .and output(/You must pass `devices_file`/)
          .to_stderr_from_any_process
        expect(Process.last_status).not_to be_success
      end
    end

    context 'with devices_file' do
      # rubocop:disable RSpec/InstanceVariable
      before do
        @reader, @writer = IO.pipe
        @pid = spawn(RbConfig.ruby, File.expand_path('../support/servers/proxy.rb', __dir__), err: @writer)
        at_exit { Process.kill('INT', @pid) } # In case rspec suddenly dies before cleanup
        Timeout.timeout(5) do
          sleep(0.1) until @reader.readline.include?('#start')
        end
      end

      after do |example|
        Process.kill('INT', @pid)
        @writer.close
        IO.copy_stream(@reader, $stderr) if example.exception
      end
      # rubocop:enable RSpec/InstanceVariable

      context 'when adding, deleting and renaming random devices' do
        it 'registers new devices' do
          Timeout.timeout(10) do
            expect { system(env, 'fastlane', 'run', 'sync_devices', "devices_file:#{fixture('system/0.tsv')}", exception: true) }
              .to output(/(Created.+){10}.+Successfully registered new devices/m)
              .to_stdout_from_any_process
              .and output('')
              .to_stderr_from_any_process
            expect { system(env, 'fastlane', 'run', 'sync_devices', "devices_file:#{fixture('system/1.tsv')}", exception: true) }
              .to output(/Successfully registered new devices/)
              .to_stdout_from_any_process
              .and output('')
              .to_stderr_from_any_process
            devices = URI.open('https://localhost:4567/v1/devices', ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
              .read
              .then { |data| JSON.parse(data) }
              .then { |json| Spaceship::ConnectAPI::Models.parse(json) }
            expect(devices.size).to eq 28
            expect(devices.count(&:enabled?)).to eq 21
          end
        end
      end
    end
  end
end
