# frozen_string_literal: true

# API server that mocks AppStore Connect API.

require 'digest'
require 'json'
require 'sinatra'

Device = Struct.new(
  :id,
  :deviceClass,
  :model,
  :name,
  :platform,
  :status,
  :udid,
  :addedDate
) do
  def attributes
    to_h.slice(*members[1..])
  end
end

# Custom error class for device not found.
class DeviceNotFound < StandardError
  attr_reader :device_id

  def initialize(device_id)
    super("Device not found: #{device_id}")
    @device_id = device_id
  end
end

def device_response(device)
  links = { self: url('/v1/devices') }
  {
    data: {
      attributes: device.attributes,
      id: device.id,
      type: :devices,
      links: links
    },
    links: links
  }.to_json
end

configure do
  enable :lock
  set :default_content_type, :json
  set :host_authorization, { permitted_hosts: [] }
  set :show_exceptions, :after_handler
  set :devices, []
end

# https://developer.apple.com/documentation/appstoreconnectapi/list_devices
get '/v1/devices' do # rubocop:disable Metrics/BlockLength
  unsupported_fields = %i{fields[devices] filter[id] filter[name] filter[platform] filter[status] filter[udid] sort}
  unsupported_fields.each do |field|
    raise NotImplementedError, "#{field} has not been implemented yet" if params.include?(field)
  end
  limit = [params.fetch(:limit, 200).to_i, 200].min
  {
    data: settings.devices[0..limit].map do |device|
      {
        attributes: device.attributes,
        id: device.id,
        type: :devices,
        links: {
          self: url('/v1/devices')
        }
      }
    end,
    links: {
      self: url('/v1/devices')
    },
    meta: {
      paging: {
        total: settings.devices.length,
        limit: limit
      }
    }
  }.to_json
end

# https://developer.apple.com/documentation/appstoreconnectapi/register_a_new_device
post '/v1/devices' do
  params = JSON.parse(request.body.read, symbolize_names: true)
  data = params.fetch(:data)
  attributes = data.fetch(:attributes)
  name = attributes.fetch(:name)
  platform = attributes.fetch(:platform)
  udid = attributes.fetch(:udid)
  device = Device.new(
    Digest::MD5.hexdigest(udid).upcase,
    nil,
    nil,
    name,
    platform,
    'ENABLED',
    udid,
    Time.now.getutc.strftime('%Y-%m-%dT%H:%M:%SZ')
  )
  settings.devices << device
  status 201
  device_response(device)
end

# https://developer.apple.com/documentation/appstoreconnectapi/read_device_information
get '/v1/devices/:id' do |id|
  raise NotImplementedError, 'fields[devices] has not been implemented yet' if params.include?('fields[devices]')

  device = settings.devices.detect { |d| d.id == id }
  raise DeviceNotFound, id unless device

  device_response(device)
end

# https://developer.apple.com/documentation/appstoreconnectapi/modify_a_registered_device
patch '/v1/devices/:id' do |id|
  params = JSON.parse(request.body.read, symbolize_names: true)
  data = params.fetch(:data)
  attributes = data.fetch(:attributes)
  raise "path parameter id=#{id} does not match post body id: #{data[:id]}" if data[:id] != id

  device = settings.devices.detect { |d| d.id == id }
  raise DeviceNotFound, id unless device

  device.name = attributes.fetch(:name, device.name)
  device.status = attributes.fetch(:status, device.status)
  device_response(device)
end

error DeviceNotFound do
  status 404
  {
    errors: [
      code: 'NOT_FOUND',
      status: 404,
      id: env['sinatra.error'].device_id
    ]
  }.to_json
end
