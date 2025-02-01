# frozen_string_literal: true

require 'json'
require 'rack/test'
require_relative '../../server/app'

describe 'app' do # rubocop:disable RSpec/DescribeClass
  # rubocop:disable RSpec/ExampleLength

  include Rack::Test::Methods

  let(:app) { Sinatra::Application }
  let(:devices) { [] }
  let(:last_response_body_json) { JSON.parse(last_response.body, symbolize_names: true) }

  before { app.set :devices, devices }

  describe 'GET /v1/devices' do
    context 'when there are no devices' do
      it 'returns an empty list of devices' do
        get '/v1/devices'

        aggregate_failures do
          expect(last_response).to be_ok
          expect(last_response_body_json).to eq(
            {
              data: [],
              links: {
                self: 'http://example.org/v1/devices'
              },
              meta: {
                paging: {
                  total: 0,
                  limit: 200
                }
              }
            }
          )
        end
      end
    end

    context 'when there are devices' do
      let(:devices) do
        [
          Device.new(
            'ID',
            nil,
            nil,
            'NAME',
            'IOS',
            'ENABLED',
            'UDID',
            '2020-01-01T00:00:00Z'
          )
        ]
      end

      it 'returns a list of devices' do
        get '/v1/devices'

        aggregate_failures do
          expect(last_response).to be_ok
          expect(last_response_body_json).to eq(
            {
              data: devices.map do |device|
                {
                  attributes: device.attributes,
                  id: device.id,
                  type: 'devices',
                  links: {
                    self: 'http://example.org/v1/devices'
                  }
                }
              end,
              links: {
                self: 'http://example.org/v1/devices'
              },
              meta: {
                paging: {
                  total: 1,
                  limit: 200
                }
              }
            }
          )
        end
      end
    end
  end

  describe 'POST /v1/devices' do
    context 'when the request is valid' do
      before { allow(Time).to receive(:now).and_return(Time.utc(2020, 1, 1)) }

      it 'registers a new device' do
        header 'Content-Type', 'application/json'
        post '/v1/devices', {
          data: {
            attributes: {
              name: 'NAME',
              platform: 'IOS',
              udid: 'UDID'
            }
          }
        }.to_json

        aggregate_failures do
          expect(last_response).to be_created
          expect(last_response_body_json).to eq(
            {
              data: {
                attributes: {
                  addedDate: '2020-01-01T00:00:00Z',
                  deviceClass: nil,
                  model: nil,
                  name: 'NAME',
                  platform: 'IOS',
                  status: 'ENABLED',
                  udid: 'UDID'
                },
                id: 'E51BE273E7C5FBA69926D343887715B7',
                type: 'devices',
                links: {
                  self: 'http://example.org/v1/devices'
                }
              },
              links: {
                self: 'http://example.org/v1/devices'
              }
            }
          )
          expect(app.settings.devices).to include(an_instance_of(Device))
        end
      end
    end
  end

  describe 'GET /v1/devices/:id' do
    context 'when the device does not exist' do
      it 'returns a 404 response' do
        get '/v1/devices/ID'

        aggregate_failures do
          expect(last_response).to be_not_found
          expect(last_response_body_json).to eq(
            {
              errors: [
                {
                  code: 'NOT_FOUND',
                  status: 404,
                  id: 'ID'
                }
              ]
            }
          )
        end
      end
    end

    context 'when the device exists' do
      let(:devices) do
        [
          Device.new(
            'ID',
            nil,
            nil,
            'NAME',
            'IOS',
            'ENABLED',
            'UDID',
            '2020-01-01T00:00:00Z'
          )
        ]
      end

      it 'returns the device' do
        get '/v1/devices/ID'

        aggregate_failures do
          expect(last_response).to be_ok
          expect(last_response_body_json).to eq(
            {
              data: {
                attributes: {
                  addedDate: '2020-01-01T00:00:00Z',
                  deviceClass: nil,
                  model: nil,
                  name: 'NAME',
                  platform: 'IOS',
                  status: 'ENABLED',
                  udid: 'UDID'
                },
                id: 'ID',
                type: 'devices',
                links: {
                  self: 'http://example.org/v1/devices'
                }
              },
              links: {
                self: 'http://example.org/v1/devices'
              }
            }
          )
        end
      end
    end
  end

  describe 'PATCH /v1/devices/:id' do
    context 'when the device does not exist' do
      it 'returns a 404 response' do
        header 'Content-Type', 'application/json'
        patch '/v1/devices/ID', {
          data: {
            id: 'ID',
            attributes: {
              name: 'NEW NAME'
            }
          }
        }.to_json

        aggregate_failures do
          expect(last_response).to be_not_found
          expect(last_response_body_json).to eq(
            {
              errors: [
                {
                  code: 'NOT_FOUND',
                  status: 404,
                  id: 'ID'
                }
              ]
            }
          )
        end
      end
    end

    context 'when the device exists' do
      let(:devices) do
        [
          Device.new(
            'ID',
            nil,
            nil,
            'NAME',
            'IOS',
            'ENABLED',
            'UDID',
            '2020-01-01T00:00:00Z'
          )
        ]
      end

      it 'modifies the device' do
        header 'Content-Type', 'application/json'
        patch '/v1/devices/ID', {
          data: {
            id: 'ID',
            attributes: {
              name: 'NEW NAME'
            }
          }
        }.to_json

        aggregate_failures do
          expect(last_response).to be_ok
          expect(last_response_body_json).to eq(
            {
              data: {
                attributes: {
                  addedDate: '2020-01-01T00:00:00Z',
                  deviceClass: nil,
                  model: nil,
                  name: 'NEW NAME',
                  platform: 'IOS',
                  status: 'ENABLED',
                  udid: 'UDID'
                },
                id: 'ID',
                type: 'devices',
                links: {
                  self: 'http://example.org/v1/devices'
                }
              },
              links: {
                self: 'http://example.org/v1/devices'
              }
            }
          )
          expect(app.settings.devices.first.name).to eq 'NEW NAME'
        end
      end
    end
  end

  # rubocop:enable RSpec/ExampleLength
end
