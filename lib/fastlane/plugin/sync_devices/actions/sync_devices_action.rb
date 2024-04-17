# frozen_string_literal: true

require 'credentials_manager'
require 'fastlane/action'
require_relative '../helper/sync_devices_helper'

module Fastlane # rubocop:disable Style/Documentation
  # @see https://rubydoc.info/gems/fastlane/FastlaneCore/UI
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  # @see https://rubydoc.info/gems/fastlane/Fastlane/Actions
  module Actions
    # Fastlane action to synchronize remote devices on Apple Developer Portal with local devices file.
    class SyncDevicesAction < Action # rubocop:disable Metrics/ClassLength
      include Fastlane::Helper::SyncDevicesHelper

      # The main entry point of this plugin.
      #
      # @param params [Hash] options passed to this plugin. See {.available_options} for details.
      # @option params [Boolean] :dry_run
      # @option params [String] :devices_file
      # @option params [String, nil] :api_key_path
      # @option params [Hash, nil] :api_key
      # @option params [String, nil] :team_id
      # @option params [String, nil] :team_name
      # @option params [String, nil] :username
      # @return [void]
      # @see https://rubydoc.info/gems/fastlane/Fastlane%2FAction.run Fastlane::Action.run
      def self.run(params)
        require 'spaceship/connect_api'

        devices_file = params[:devices_file]
        UI.user_error!('You must pass `devices_file`. Please check the readme.') unless devices_file
        spaceship_login(params)
        new_devices = DevicesFile.load(devices_file)

        UI.message('Fetching list of currently registered devices...')
        current_devices = Spaceship::ConnectAPI::Device.all
        patch = DevicesPatch.new(current_devices, new_devices)
        patch.apply!(dry_run: params[:dry_run])

        UI.success('Successfully registered new devices.')
      end

      # Authenticates the user with AppStore Connect API or Apple Developer Portal.
      #
      # @param (see .run)
      # @return [void]
      def self.spaceship_login(params)
        api_token = Spaceship::ConnectAPI::Token.from(hash: params[:api_key], filepath: params[:api_key_path])
        if api_token
          UI.message('Creating authorization token for App Store Connect API')
          Spaceship::ConnectAPI.token = api_token
        elsif Spaceship::ConnectAPI.token
          UI.message('Using existing authorization token for App Store Connect API')
        else
          UI.message("Login to App Store Connect (#{params[:username]})")
          credentials = CredentialsManager::AccountManager.new(user: params[:username])
          Spaceship::ConnectAPI.login(credentials.user, credentials.password, use_portal: true, use_tunes: false)
          UI.message('Login Successful')
        end
      end
      private_class_method :spaceship_login

      # Description of this plugin.
      #
      # @return [String]
      # @see https://rubydoc.info/gems/fastlane/Fastlane%2FAction.description Fastlane::Action.description
      def self.description
        'Synchronize your devices with Apple Developer Portal.'
      end

      # Authors of this plugin.
      #
      # @return [Array<String>]
      # @see https://rubydoc.info/gems/fastlane/Fastlane%2FAction.authors Fastlane::Action.authors
      def self.authors
        ['Ryosuke Ito']
      end

      # Detailed description of this plugin.
      #
      # @return [String]
      # @see https://rubydoc.info/gems/fastlane/Fastlane%2FAction.details Fastlane::Action.details
      def self.details
        <<~DETAILS
          This will synchronize iOS/Mac devices with the Apple Developer Portal so that you can include them in your provisioning profiles.
          Unlike `register_devices` action, this action may disable, enable or rename devices.
          Maybe it sounds dangerous but actually it does not delete anything, so you can recover the changes by yourself if needed.

          The action will connect to the Apple Developer Portal using AppStore Connect API.
        DETAILS
      end

      # Available options of this plugin.
      #
      # @return [Array<FastlaneCore::ConfigItem>]
      #
      # @see https://rubydoc.info/gems/fastlane/Fastlane%2FAction.available_options Fastlane::Action.available_options
      # @see https://rubydoc.info/gems/fastlane/FastlaneCore/ConfigItem FastlaneCore::ConfigItem
      def self.available_options # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        [
          FastlaneCore::ConfigItem.new(
            key: :dry_run,
            env_name: 'FL_SYNC_DEVICES_DRY_RUN',
            description: 'Do not modify the registered devices but just print what will be done',
            type: Boolean,
            default_value: false,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :devices_file,
            env_name: 'FL_SYNC_DEVICES_FILE',
            description: 'Provide a path to a file with the devices to register. ' \
                         'For the format of the file see the examples',
            optional: true,
            verify_block: proc do |value|
              UI.user_error!("Could not find file '#{value}'") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :api_key_path,
            env_names: %w[FL_SYNC_DEVICES_API_KEY_PATH APP_STORE_CONNECT_API_KEY_PATH],
            description: 'Path to your App Store Connect API Key JSON file ' \
                         '(https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file)',
            optional: true,
            conflicting_options: [:api_key],
            verify_block: proc do |value|
              UI.user_error!("Couldn't find API key JSON file at path '#{value}'") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :api_key,
            env_names: %w[FL_SYNC_DEVICES_API_KEY APP_STORE_CONNECT_API_KEY],
            description: 'Your App Store Connect API Key information ' \
                         '(https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-hash-option)',
            type: Hash,
            default_value: Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::APP_STORE_CONNECT_API_KEY],
            default_value_dynamic: true,
            optional: true,
            sensitive: true,
            conflicting_options: [:api_key_path]
          ),
          FastlaneCore::ConfigItem.new(
            key: :team_id,
            env_name: 'SYNC_DEVICES_TEAM_ID',
            code_gen_sensitive: true,
            default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_id),
            default_value_dynamic: true,
            description: "The ID of your Developer Portal team if you're in multiple teams",
            optional: true,
            verify_block: proc do |value|
              ENV['FASTLANE_TEAM_ID'] = value.to_s
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :team_name,
            env_name: 'SYNC_DEVICES_TEAM_NAME',
            description: "The name of your Developer Portal team if you're in multiple teams",
            optional: true,
            code_gen_sensitive: true,
            default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_name),
            default_value_dynamic: true,
            verify_block: proc do |value|
              ENV['FASTLANE_TEAM_NAME'] = value.to_s
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :username,
            env_name: 'DELIVER_USER',
            description: 'Optional: Your Apple ID',
            optional: true,
            default_value: CredentialsManager::AppfileConfig.try_fetch_value(:apple_id),
            default_value_dynamic: true
          )
        ]
      end

      # Whether if this plugin is supported on the platform.
      #
      # @param _platform [Symbol] unused
      # @return [true]
      # @see https://rubydoc.info/gems/fastlane/Fastlane%2FAction.is_supported%3F Fastlane::Action.is_supported?
      def self.is_supported?(_platform) # rubocop:disable Naming/PredicateName
        true
      end

      # Example usages of this plugin.
      #
      # @return [Array<String>]
      # @see https://rubydoc.info/gems/fastlane/Fastlane%2FAction.example_code Fastlane::Action.example_code
      def self.example_code
        [
          <<~EX_1,
            # Provide TSV file
            sync_devices(devices_file: '/path/to/devices.txt')
          EX_1
          <<~EX_2,
            # Provide Property List file, with configuring credentials
            sync_devices(
              devices_file: '/path/to/devices.deviceids',
              team_id: 'ABCDEFGHIJ',
              api_key_path: '/path/to/api_key.json'
            )
          EX_2
          <<~EX_3
            # Just check what will occur
            sync_devices(devices_file: '/path/to/devices.txt', dry_run: true)
          EX_3
        ]
      end

      # Category of this plugin.
      #
      # @return [Symbol]
      # @see https://rubydoc.info/gems/fastlane/Fastlane%2FAction.category Fastlane::Action.category
      def self.category
        :code_signing
      end
    end
  end
end
