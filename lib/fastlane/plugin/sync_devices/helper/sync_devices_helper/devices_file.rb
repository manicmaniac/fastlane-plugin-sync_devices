module Fastlane
  module Helper
    module SyncDevicesHelper
      module DevicesFile
        # @param [String] path
        # @return [Array<Spaceship::ConnectAPI::Device>]
        def self.load(path)
          case File.extname(path)
          when '.tsv', '.txt'
            load_tsv(path)
          when '.deviceids', '.plist', '.xml'
            load_plist(path)
          else
            require 'cfpropertylist'

            begin
              load_plist(path) or load_tsv(path)
            rescue CFFormatError
              load_tsv(path)
            end
          end
        end

        # @param [String] path
        # @return [Array<Spaceship::ConnectAPI::Device>]
        def self.load_tsv(path)
          require 'csv'
          require 'spaceship/connect_api'

          raise InvalidDevicesFile.empty_file(path) if File.empty?(path)

          table = CSV.read(path, headers: true, col_sep: "\t")
          validate_headers(table.headers, path)

          devices = table.map.with_index(2) do |row, line_number|
            validate_row(row, path, line_number)
            Spaceship::ConnectAPI::Device.new(
              nil,
              {
                name: row['Device Name'],
                udid: row['Device ID'],
                platform: parse_platform(row['Device Platform'], path),
                status: Spaceship::ConnectAPI::Device::Status::ENABLED
              }
            )
          end
          validate_devices(devices, path)
          devices
        end

        # @param [String] path
        # @return [Array<Spaceship::ConnectAPI::Device>]
        def self.load_plist(path)
          require 'cfpropertylist'
          require 'spaceship/connect_api'

          raise InvalidDevicesFile.empty_file(path) if File.empty?(path)

          plist = CFPropertyList::List.new(file: path)
          items = CFPropertyList.native_types(plist.value)['Device UDIDs']
          devices = items.map.with_index do |item, index|
            validate_dict_item(item, index, path)
            Spaceship::ConnectAPI::Device.new(
              nil,
              {
                name: item['deviceName'],
                udid: item['deviceIdentifier'],
                platform: parse_platform(item['devicePlatform'], path),
                status: Spaceship::ConnectAPI::Device::Status::ENABLED
              }
            )
          end
          validate_devices(devices, path)
          devices
        end

        SUPPORTED_FORMATS = %i[tsv plist].freeze

        def self.dump(devices, path, format: :tsv)
          raise "Unsupported format '#{format}'." unless SUPPORTED_FORMATS.include?(format)

          case format
          when :tsv
            dump_tsv(devices, path)
          when :plist
            dump_plist(devices, path)
          end
        end

        def self.dump_tsv(devices, path)
          require 'csv'

          CSV.open(path, 'w', col_sep: "\t", headers: true, write_headers: true) do |csv|
            csv << HEADERS
            devices.each do |device|
              csv << [device.udid, device.name, device.platform]
            end
          end
        end

        def self.dump_plist(devices, path)
          require 'cfpropertylist'

          plist = CFPropertyList::List.new
          plist.value = CFPropertyList.guess({
            'Device UDIDs' => devices.map do |device|
              {
                deviceIdentifier: device.udid,
                deviceName: device.name,
                devicePlatform: device.platform.downcase
              }
            end
          })
          plist.save(path, CFPropertyList::List::FORMAT_XML)
        end

        MAX_DEVICE_NAME_LENGTH = 50

        # @param [Array<Spaceship::ConnectAPI::Device>] devices
        # @raise [InvalidDevicesFile]
        def self.validate_devices(devices, path)
          seen_udids = []
          devices.each do |device|
            udid = device.udid&.downcase
            raise InvalidDevicesFile.invalid_udid(device.udid, path) unless udid.match(udid_regex_for_platform(device.platform))
            raise InvalidDevicesFile.udid_not_unique(device.udid, path) if seen_udids.include?(udid)
            raise InvalidDevicesFile.device_name_too_long(device.name, path) if device.name.size > MAX_DEVICE_NAME_LENGTH

            seen_udids << udid
          end
        end
        private_class_method :validate_devices

        # @param [String] platform_string
        # @return [String]
        def self.parse_platform(platform_string, path)
          Spaceship::ConnectAPI::Platform.map(platform_string || 'ios')
        rescue RuntimeError => e
          if e.message.include?('Cannot find a matching platform')
            raise InvalidDevicesFile.unknown_platform(platform_string, path)
          end

          raise
        end
        private_class_method :parse_platform

        HEADERS = ['Device ID', 'Device Name', 'Device Platform'].freeze
        private_constant :HEADERS

        SHORT_HEADERS = HEADERS[0..1].freeze
        private_constant :SHORT_HEADERS

        # @param [Array<String>] headers
        # @param [String] path
        # @raise [InvalidDevicesFile]
        def self.validate_headers(headers, path)
          unless [HEADERS, SHORT_HEADERS].include?(headers.compact)
            raise InvalidDevicesFile.invalid_headers(path, 1)
          end
        end
        private_class_method :validate_headers

        # @param [CSV::Row] row
        # @param [String] path
        # @param [Integer] line_number
        # @raise [InvalidDevicesFile]
        def self.validate_row(row, path, line_number)
          case row.fields.compact.size
          when 0, 1
            raise InvalidDevicesFile.columns_too_short(path, line_number)
          when 2, 3
            # Does nothing
          else
            raise InvalidDevicesFile.columns_too_long(path, line_number)
          end
        end
        private_class_method :validate_row

        REQUIRED_KEYS = %w[deviceName deviceIdentifier].freeze
        private_constant :REQUIRED_KEYS

        # @param [Hash<String, String>] item
        # @param [Integer] index
        # @param [String] path
        # @raise [InvalidDevicesFile]
        def self.validate_dict_item(item, index, path)
          REQUIRED_KEYS.each do |key|
            unless item.key?(key)
              entry = ":Device UDIDs:#{index}:#{key}"
              raise InvalidDevicesFile.missing_key(entry, path)
            end
          end
        end
        private_class_method :validate_dict_item

        def self.udid_regex_for_platform(platform)
          case platform
          when Spaceship::ConnectAPI::Platform::IOS
            # @see https://www.theiphonewiki.com/wiki/UDID
            /^(?:[0-9]{8}-[0-9a-f]{16}|[0-9a-f]{40})$/
          when Spaceship::ConnectAPI::Platform::MAC_OS
            /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
          else
            # I have no idea about UDID of other platforms (e.g. tvOS, watchOS).
            /.+/
          end
        end
        private_class_method :udid_regex_for_platform
      end

      class InvalidDevicesFile < StandardError
        SAMPLE_FILE_URL = 'https://developer.apple.com/account/resources/downloads/Multiple-Upload-Samples.zip'

        attr_reader :path, :line_number, :entry

        # @param [String] message
        # @param [String] path
        # @param [String, nil] line_number
        # @param [String, nil] entry
        def initialize(message, path, line_number: nil, entry: nil)
          super(format(message, { location: [path, line_number].join(':'), url: SAMPLE_FILE_URL }))
          @path = path
          @line_number = line_number
          @entry = entry
        end

        def self.empty_file(path)
          new(
            'File %<location>s is empty, please provide a file according to the Apple Sample UDID file (%<url>s)',
            path
          )
        end

        def self.invalid_headers(path, line_number)
          new(
            'Invalid header line at %<location>s, please provide a file according to the Apple Sample UDID file (%<url>s)',
            path,
            line_number: line_number
          )
        end

        def self.columns_too_short(path, line_number)
          new(
            "Invalid device line at %<location>s, ensure you are using tabs (NOT spaces). See Apple's sample/spec here: %<url>s",
            path,
            line_number: line_number
          )
        end

        def self.columns_too_long(path, line_number)
          new(
            'Invalid device line at %<location>s, please provide a file according to the Apple Sample UDID file (%<url>s)',
            path,
            line_number: line_number
          )
        end

        def self.missing_key(entry, path)
          new(
            "Invalid device file at %<location>s, each item must have a required key '#{entry}', See Apple's sample/spec here: %<url>s",
            path,
            entry: entry
          )
        end

        def self.invalid_udid(udid, path)
          new(
            "Invalid UDID '#{udid}' at %<location>s, the UDID is not in the correct format",
            path
          )
        end

        def self.udid_not_unique(udid, path)
          new(
            "Invalid UDID '#{udid}' at %<location>s, there's another device with the same UDID is defined",
            path
          )
        end

        def self.device_name_too_long(name, path)
          new(
            "Invalid device name '#{name}' at %<location>s, a device name must be less than or equal to #{DevicesFile::MAX_DEVICE_NAME_LENGTH} characters long",
            path
          )
        end

        def self.unknown_platform(platform, path)
          new(
            "Unknown platform '#{platform}' at %<location>s",
            path
          )
        end
      end
    end
  end
end
