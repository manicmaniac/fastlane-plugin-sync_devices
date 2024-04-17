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

devices = []

enable :lock
set :default_content_type, :json

# https://developer.apple.com/documentation/appstoreconnectapi/list_devices
get '/v1/devices' do
  unsupported_fields = %i{fields[devices] filter[id] filter[name] filter[platform] filter[status] filter[udid] sort}
  unsupported_fields.each do |field|
    raise NotImplementedError, "#{field} has not been implemented yet" if params.include?(field)
  end
  limit = [params.fetch(:limit, 200).to_i, 200].min
  {
    data: devices[0..limit].map do |device|
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
        total: devices.length,
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
  devices << device
  status 201
  device_response(device)
end

# https://developer.apple.com/documentation/appstoreconnectapi/read_device_information
get '/v1/devices/:id' do |id|
  raise NotImplementedError, 'fields[devices] has not been implemented yet' if params.include?('fields[devices]')

  device = devices.detect { |d| d.id == id }
  unless device
    status 404
    {
      errors: [
        code: 'NOT_FOUND',
        status: 404,
        id: id
      ]
    }.to_json
  end
  device_response(device)
end

# https://developer.apple.com/documentation/appstoreconnectapi/modify_a_registered_device
patch '/v1/devices/:id' do |id|
  params = JSON.parse(request.body.read, symbolize_names: true)
  data = params.fetch(:data)
  attributes = data.fetch(:attributes)
  raise "path parameter id=#{id} does not match post body id: #{data[:id]}" if data[:id] != id

  device = devices.detect { |d| d.id == id }
  unless device
    status 404
    {
      errors: [
        code: 'NOT_FOUND',
        status: 404,
        id: id
      ]
    }.to_json
  end
  device.name = attributes.fetch(:name, device.name)
  device.status = attributes.fetch(:status, device.status)
  device_response(device)
end
