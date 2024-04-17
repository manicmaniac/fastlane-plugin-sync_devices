# frozen_string_literal: true

require 'spaceship'
require 'timeout'

describe 'app' do # rubocop:disable RSpec::DescribeClass
  around do |example|
    IO.pipe do |reader, writer|
      pid = spawn(RbConfig.ruby, File.expand_path('app.rb', __dir__), err: writer)
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

  let(:token) { instance_double(Spaceship::ConnectAPI::Token, expired?: false, text: '', refresh!: nil) }
  let(:client) do
    Class.new(Spaceship::ConnectAPI::Provisioning::Client) do
      def hostname
        'http://localhost:4567/v1/'
      end
    end.new(token: token)
  end

  example 'user can manipulate devices' do # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    aggregate_failures 'list devices' do
      devices = Spaceship::ConnectAPI::Device.all(client: client)
      expect(devices).to be_empty
    end

    aggregate_failures 'create a device' do
      device = Spaceship::ConnectAPI::Device.create(client: client, name: 'foo', platform: 'IOS', udid: 'UDID')
      expect(device).to have_attributes(
        {
          id: kind_of(String),
          device_class: nil,
          model: nil,
          name: 'foo',
          platform: 'IOS',
          status: 'ENABLED',
          udid: 'UDID',
          added_date: kind_of(String)
        }
      )
      devices = Spaceship::ConnectAPI::Device.all(client: client)
      expect(devices.map(&:id)).to include(device.id)
    end

    aggregate_failures 'disable a device' do
      device = Spaceship::ConnectAPI::Device.disable('UDID', client: client)
      expect(device.enabled?).to be false
      devices = Spaceship::ConnectAPI::Device.all(client: client)
      expect(devices.detect { |d| d.id == device.id }).not_to be_enabled
    end

    aggregate_failures 'rename a device' do
      device = Spaceship::ConnectAPI::Device.rename('UDID', 'bar', client: client)
      expect(device.name).to eq 'bar'
      devices = Spaceship::ConnectAPI::Device.all(client: client)
      expect(devices.detect { |d| d.id == device.id }.name).to eq 'bar'
    end
  end
end
