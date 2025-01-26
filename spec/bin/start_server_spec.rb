# frozen_string_literal: true

require 'net/http'
require 'uri'

describe 'start_server' do # rubocop:disable RSpec::DescribeClass
  include CommandLineHelper

  let(:executable_path) { File.expand_path('../../bin/start_server', __dir__) }

  it('executable exists') { expect(File).to exist(executable_path) }

  shared_examples 'printing help' do |args:, status:|
    it "prints help and exit with status #{status}" do
      aggregate_failures do
        expect { system_ruby({}, executable_path, *args) }
          .to output(/Usage: start_server \[-h\]/)
          .to_stdout_from_any_process
          .and output('')
          .to_stderr_from_any_process
        expect(Process.last_status.exitstatus).to eq(status)
      end
    end
  end

  describe '(no args)' do
    it_behaves_like 'printing help', args: [], status: 1
  end

  describe '(too short args)' do
    it_behaves_like 'printing help', args: ['foo'], status: 1
  end

  describe '(too long args)' do
    it_behaves_like 'printing help', args: %w[foo bar baz], status: 1
  end

  describe '-h' do
    it_behaves_like 'printing help', args: ['-h'], status: 0
  end

  describe '--help' do
    it_behaves_like 'printing help', args: ['--help'], status: 0
  end

  describe '<APP_PORT> <PROXY_PORT>' do
    around do |example|
      IO.pipe do |reader, writer|
        pid = spawn_ruby({}, executable_path, '4567', '8888', err: writer)
        at_exit { Process.kill('INT', pid) } # In case rspec suddenly dies before cleanup
        Timeout.timeout(5) do
          sleep(0.1) until reader.readline.include?('#start')
        end
        example.run
        Process.kill('INT', pid)
        writer.close
        IO.copy_stream(reader, $stderr) if example.exception
      end
    end

    it 'starts the server' do
      url = URI.parse('https://api.appstoreconnect.apple.com/v1/devices')
      proxy = URI.parse('https://localhost:8888')

      http = Net::HTTP.new(url.host, url.port, proxy.host, proxy.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(url.path)
      response = http.request(request)

      expect(response.code).to eq('200')
    end
  end
end
