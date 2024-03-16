# frozen_string_literal: true

require 'digest'
require 'securerandom'
require 'spaceship'

module DeviceHelper
  def random_device
    name_length = (1...50).to_a.sample
    platform = random_platform
    udid = random_udid(platform)
    Spaceship::ConnectAPI::Device.new(
      nil,
      {
        name: SecureRandom.alphanumeric(name_length),
        udid: udid,
        platform: platform,
        status: [
          Spaceship::ConnectAPI::Device::Status::ENABLED,
          Spaceship::ConnectAPI::Device::Status::DISABLED
        ].sample
      }
    )
  end

  def random_device_tsv_row
    device = random_device
    [
      device.udid,
      device.name,
      device.platform
    ].join("\t")
  end

  def random_platform
    %i[ios mac].sample
  end

  def random_udid(platform)
    case platform
    when :ios
      if [true, false].sample
        [CHIP_IDS.sample, SecureRandom.hex(8).upcase].join('-')
      else
        Digest::SHA1.hexdigest(SecureRandom.random_bytes(32))
      end
    when :mac
      [
        SecureRandom.hex(4),
        SecureRandom.hex(2),
        SecureRandom.hex(2),
        SecureRandom.hex(2),
        SecureRandom.hex(6)
      ].join('-')
    else
      raise "Unsuported platform #{platform}."
    end
  end

  # https://www.theiphonewiki.com/wiki/CHIP
  CHIP_IDS = %w[
    00008930
    00008940
    00008942
    00008945
    00008947
    00008950
    00008955
    00008960
    00007000
    00007001
    00008000
    00008001
    00008003
    00008010
    00008011
    00008015
    00008020
    00008027
    00008030
    00008101
    00008110
    00008120
  ].freeze
  private_constant :CHIP_IDS
end
