require 'spaceship'
require 'timeout'

Device = Spaceship::ConnectAPI::Device

describe 'app' do # rubocop:disable RSpec::DescribeClass
  # rubocop:disable RSpec/InstanceVariable
  before do
    @reader, @writer = IO.pipe
    @pid = spawn(RbConfig.ruby, File.expand_path('app.rb', __dir__), err: @writer)
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

  let(:token) { instance_double(Spaceship::ConnectAPI::Token, expired?: false, text: '', refresh!: nil) }
  let(:client) do
    Class.new(Spaceship::ConnectAPI::Provisioning::Client) do
      def hostname
        'http://localhost:4567/v1/'
      end
    end.new(token: token)
  end

  example 'user can manipulate devices' do
    # list
    devices = Device.all(client: client)
    expect(devices).to be_empty

    # create
    device = Device.create(client: client, name: 'foo', platform: 'IOS', udid: 'UDID')
    expect(device.enabled?).to be true

    devices = Device.all(client: client)
    expect(devices.map(&:id)).to include(device.id)

    # disable
    device = Device.disable('UDID', client: client)
    expect(device.enabled?).to be false

    devices = Device.all(client: client)
    expect(devices.detect { |d| d.id == device.id }).not_to be_enabled

    # rename
    device = Device.rename('UDID', 'bar', client: client)
    expect(device.name).to eq 'bar'

    devices = Device.all(client: client)
    expect(devices.detect { |d| d.id == device.id }.name).to eq 'bar'
  end
end
