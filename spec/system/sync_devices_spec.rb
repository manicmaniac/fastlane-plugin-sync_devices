# frozen_string_literal: true

require 'open3'
require 'tempfile'
require 'timeout'

describe 'fastlane-plugin-sync_devices' do
  include DeviceHelper
  include FixtureHelper

  let(:env) do
    {
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
      stdout, stderr, status = Open3.capture3(env, 'fastlane', 'action', 'sync_devices')
      expect(status).to be_success
      expect(stdout).not_to be_empty
      expect(stderr).to be_empty
    end
  end

  describe 'fastlane run sync_devices' do
    context 'without arguments' do
      it 'fails with error messages' do
        stdout, stderr, status = Open3.capture3(env, 'fastlane', 'run', 'sync_devices')
        expect(status).not_to be_success
        expect(stdout).not_to be_empty
        expect(stderr).to eq "\n[!] You must pass `devices_file`. Please check the readme.\n"
      end
    end

    context 'with devices_file' do
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

      it 'registers new devices' do
        Tempfile.open do |f|
          f.puts("Device ID\tDevice Name\tDevice Platform")
          100.times { f.puts(random_device_tsv_row) }
          f.rewind

          stdout, stderr, status = Open3.capture3(env, 'fastlane', 'run', 'sync_devices', "devices_file:#{f.path}")
          expect(status).to be_success
          expect(stdout).to match /(Created.+){100}.+Successfully registered new devices/m
          expect(stderr).to be_empty
        end
      end

      it 'loads devices from stdin' do
        lines = ["Device ID\tDevice Name\tDevice Platform"] + (0..100).map { random_device_tsv_row }
        data = lines.join("\n")

        stdout, stderr, status = Open3.capture3(env, 'fastlane', 'run', 'sync_devices', 'devices_file:/dev/fd/0', stdin_data: data)
        expect(status).to be_success
        expect(stdout).to match /(Created.+){100}.+Successfully registered new devices/m
        expect(stderr).to be_empty
      end

      xcontext 'when adding, deleting and renaming random devices' do
        let(:tempfile) { Tempfile.open }

        before do
          tempfile.puts("Device ID\tDevice Name\tDevice Platform")
          100.times { tempfile.puts(random_device_tsv_row) }
          tempfile.rewind
          system(env, 'fastlane', 'run' 'sync_devices' "devices_file:#{tempfile.path}", exception: true)
        end

        after { tempfile.close }

        it 'registers new devices' do
          Tempfile.open do |f|

            stdout, stderr, status = Open3.capture3(env, 'fastlane', 'run', 'sync_devices', "devices_file:#{f.path}")
            expect(status).to be_success
            expect(stdout).to match /(Created.+){100}.+Successfully registered new devices/m
            expect(stderr).to be_empty

            f.rewind
            content = f.lines.select.with_index { |_, i| i.even? }.join("\n")
            f.rewind
            f.write(content)
            f.truncate

            f.rewind
            puts(f.read)
          end
        end
      end
    end
  end
end
