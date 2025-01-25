# frozen_string_literal: true

module Fastlane
  module Helper
    module SyncDevicesHelper
      # Collection of methods that manipulates TSV or XML devices file.
      #
      # @see https://developer.apple.com/account/resources/downloads/Multiple-Upload-Samples.zip
      module DevicesFile # rubocop:disable Metrics/ModuleLength
        # Loads a devices file and parse it as an array of devices.
        # If the file extension is one of +.deviceids+, +.plist+ and +.xml+, this method delegates to {.load_plist},
        # otherwise to {.load_tsv}.
        #
        # @param path [String] path to the output file
        # @return [Array<Spaceship::ConnectAPI::Device>]
        def self.load(path)
          return load_plist(path) if %w[.deviceids .plist .xml].include?(File.extname(path))

          load_tsv(path)
        end

        # @param path [String]
        # @return [Array<Spaceship::ConnectAPI::Device>]
        def self.load_tsv(path)
          require 'csv'
          require 'spaceship/connect_api'

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

        # @param path [String]
        # @return [Array<Spaceship::ConnectAPI::Device>]
        def self.load_plist(path)
          require 'cfpropertylist'
          require 'spaceship/connect_api'

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

        # Dumps devices to devices file specified by path.
        # This method delegates to either of {.dump_tsv} or {.dump_plist} depending on +format+.
        #
        # @param devices [Array<Spaceship::ConnectAPI::Device>] device objects to dump
        # @param path [String] path to the output file
        # @param format [:tsv, :plist] output format
        # @return [void]
        def self.dump(devices, path, format: :tsv)
          case format
          when :tsv
            dump_tsv(devices, path)
          when :plist
            dump_plist(devices, path)
          else
            raise "Unsupported format '#{format}'."
          end
        end

        # @param devices [Array<Spaceship::ConnectAPI::Device>] device objects to dump
        # @param path [String] path to the output file
        # @return [void]
        def self.dump_tsv(devices, path)
          require 'csv'

          CSV.open(path, 'w', col_sep: "\t", headers: true, write_headers: true) do |csv|
            csv << HEADERS
            devices.each do |device|
              csv << [device.udid, device.name, device.platform]
            end
          end
        end

        # @param devices [Array<Spaceship::ConnectAPI::Device>] device objects to dump
        # @param path [String] path to the output file
        # @return [void]
        def self.dump_plist(devices, path)
          require 'cfpropertylist'

          plist = CFPropertyList::List.new
          plist.value = CFPropertyList.guess(
            {
              'Device UDIDs' => devices.map do |device|
                {
                  deviceIdentifier: device.udid,
                  deviceName: device.name,
                  devicePlatform: device.platform.downcase
                }
              end
            }
          )
          plist.save(path, CFPropertyList::List::FORMAT_XML)
        end

        # Maximum length of a device name that is permitted by Apple Developer Portal.
        #
        # @return [Integer]
        MAX_DEVICE_NAME_LENGTH = 50

        # @param devices [Array<Spaceship::ConnectAPI::Device>] device objects to dump
        # @param path [String]
        # @return [void]
        # @raise [InvalidDevicesFile]
        def self.validate_devices(devices, path) # rubocop:disable Metrics/AbcSize
          seen_udids = []
          devices.each do |device|
            udid = device.udid&.downcase
            unless udid.match(udid_regex_for_platform(device.platform))
              raise InvalidDevicesFile.invalid_udid(device.udid, path)
            end
            raise InvalidDevicesFile.udid_not_unique(device.udid, path) if seen_udids.include?(udid)

            if device.name.size > MAX_DEVICE_NAME_LENGTH
              raise InvalidDevicesFile.device_name_too_long(device.name, path)
            end

            seen_udids << udid
          end
        end
        private_class_method :validate_devices

        # @param platform_string [String]
        # @param path [String]
        # @return [String]
        def self.parse_platform(platform_string, path)
          Spaceship::ConnectAPI::BundleIdPlatform.map(platform_string || 'ios')
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
          raise InvalidDevicesFile.invalid_headers(path, 1) unless [HEADERS, SHORT_HEADERS].include?(headers.compact)
        end
        private_class_method :validate_headers

        # @param row [CSV::Row]
        # @param path [String]
        # @param line_number [Integer]
        # @return [void]
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

        # @param item [Hash<String, String>]
        # @param index [Integer]
        # @param path [String]
        # @return [void]
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

        # @param platform [String]
        # @return [Regexp]
        # @raise [TypeError] when platform is not in {Spaceship::ConnectAPI::BundleIdPlatform::ALL}.
        def self.udid_regex_for_platform(platform)
          case platform
          when Spaceship::ConnectAPI::BundleIdPlatform::IOS
            # @see https://www.theiphonewiki.com/wiki/UDID
            /^(?:[0-9]{8}-[0-9a-f]{16}|[0-9a-f]{40})$/
          when Spaceship::ConnectAPI::BundleIdPlatform::MAC_OS
            /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
          else
            # :nocov:
            raise TypeError, "Unknown platform '#{platform}' is not in #{Spaceship::ConnectAPI::BundleIdPlatform::ALL}."
            # :nocov:
          end
        end
        private_class_method :udid_regex_for_platform
      end

      # Generic error that is raised if device file is not in the valid format.
      class InvalidDevicesFile < StandardError
        # URL of example devices files.
        SAMPLE_FILE_URL = 'https://developer.apple.com/account/resources/downloads/Multiple-Upload-Samples.zip'

        # @return [String]
        attr_reader :path
        # @return [Integer]
        attr_reader :line_number
        # @return [String, nil]
        attr_reader :entry

        # @param message [String]
        # @param path [String]
        # @param line_number [String, nil]
        # @param entry [String, nil]
        def initialize(message, path, line_number: nil, entry: nil)
          super(format(message, { location: [path, line_number].join(':'), url: SAMPLE_FILE_URL }))
          @path = path
          @line_number = line_number
          @entry = entry
        end

        # @param path [String]
        # @param line_number [Integer]
        # @return [InvalidDevicesFile]
        def self.invalid_headers(path, line_number)
          message = 'Invalid header line at %<location>s, please provide a file according to ' \
                    'the Apple Sample UDID file (%<url>s)'
          new(message, path, line_number: line_number)
        end

        # @param path [String]
        # @param line_number [Integer]
        # @return [InvalidDevicesFile]
        def self.columns_too_short(path, line_number)
          message = 'Invalid device line at %<location>s, ensure you are using tabs (NOT spaces). ' \
                    "See Apple's sample/spec here: %<url>s"
          new(message, path, line_number: line_number)
        end

        # @param path [String]
        # @param line_number [Integer]
        # @return [InvalidDevicesFile]
        def self.columns_too_long(path, line_number)
          message = 'Invalid device line at %<location>s, please provide a file according to ' \
                    'the Apple Sample UDID file (%<url>s)'
          new(message, path, line_number: line_number)
        end

        # @param entry [String]
        # @param path [String]
        # @return [InvalidDevicesFile]
        def self.missing_key(entry, path)
          message = "Invalid device file at %<location>s, each item must have a required key '#{entry}', " \
                    "See Apple's sample/spec here: %<url>s"
          new(message, path, entry: entry)
        end

        # @param udid [String]
        # @param path [String]
        # @return [InvalidDevicesFile]
        def self.invalid_udid(udid, path)
          new("Invalid UDID '#{udid}' at %<location>s, the UDID is not in the correct format", path)
        end

        # @param udid [String]
        # @param path [String]
        # @return [InvalidDevicesFile]
        def self.udid_not_unique(udid, path)
          message = "Invalid UDID '#{udid}' at %<location>s, there's another device with the same UDID is defined"
          new(message, path)
        end

        # @param name [String]
        # @param path [String]
        # @return [InvalidDevicesFile]
        def self.device_name_too_long(name, path)
          message = "Invalid device name '#{name}' at %<location>s, a device name " \
                    "must be less than or equal to #{DevicesFile::MAX_DEVICE_NAME_LENGTH} characters long"
          new(message, path)
        end

        # @param platform [String]
        # @param path [String]
        # @return [InvalidDevicesFile]
        def self.unknown_platform(platform, path)
          new("Unknown platform '#{platform}' at %<location>s", path)
        end
      end
    end
  end
end
