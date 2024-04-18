# sync\_devices plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-sync_devices)
[![Gem Version](https://badge.fury.io/rb/fastlane-plugin-sync_devices.svg)](https://badge.fury.io/rb/fastlane-plugin-sync_devices)
[![Test](https://github.com/manicmaniac/fastlane-plugin-sync_devices/actions/workflows/test.yml/badge.svg)](https://github.com/manicmaniac/fastlane-plugin-sync_devices/actions/workflows/test.yml)
[![Test Coverage](https://api.codeclimate.com/v1/badges/86122943536052f82616/test_coverage)](https://codeclimate.com/github/manicmaniac/fastlane-plugin-sync_devices/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/86122943536052f82616/maintainability)](https://codeclimate.com/github/manicmaniac/fastlane-plugin-sync_devices/maintainability)

## Getting Started

This project is a [fastlane](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-sync_devices`, add it to your project by running:

```bash
fastlane add_plugin sync_devices
```

## About sync\_devices

This plugin provides a single action `sync_devices`.

`sync_devices` synchronizes your devices with Apple Developer Portal.

This plugin works similarly to fastlane official [register\_devices](https://docs.fastlane.tools/actions/register_devices/) plugin, but `sync_devices` can disable, enable and rename devices on Apple Developer Portal while `register_devices` is only capable to create new devices.

Since we can only actually _delete_ a device once a year, `sync_devices` does not _delete_ devices but just disables them when they were removed from a devices file. It's safe because you can re-enable devices whenever you want.

## Basic Usage

First of all, you need to create your own `devices.tsv` under your project repository. It is a simple tab-separated text file like the following example.

```
Device ID	Device Name	Device Platform
01234567-89ABCDEF01234567	NAME1	ios
abcdef0123456789abcdef0123456789abcdef01	NAME2	ios
01234567-89AB-CDEF-0123-4567890ABCDE	NAME3	mac
ABCDEF01-2345-6789-ABCD-EF0123456789	NAME4	mac
```

Then you can run `sync_devices` from command line.

Run `sync_devices` in dry-run mode, which does not change remote devices, so that you can see what will be done when it actually runs.

```
fastlane run sync_devices devices_file:devices.tsv dry_run:true
```

After carefully checking if the result is the same as expected, run

```
fastlane run sync_devices devices_file:devices.tsv
```

You will see the remote devices are synchronized with your devices.tsv.


## Advanced Usage

### Use Property List file instead of TSV

Apple Developer Portal also accepts a devices file in Property List format like this.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Device UDIDs</key>
	<array>
		<dict>
			<key>deviceIdentifier</key>
			<string>01234567-89ABCDEF01234567</string>
			<key>deviceName</key>
			<string>NAME1</string>
			<key>devicePlatform</key>
			<string>ios</string>
		</dict>
	</array>
</dict>
</plist>
```

If you want to use Property List format, just pass the file to `sync_devices`.

```
fastlane run sync_devices devices_file:devices.deviceids
```

Following Apple's guide, I added `.deviceids` file extension but you can use standard `.xml` or `.plist` as well.

```
fastlane run sync_devices devices_file:devices.xml
```

## Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

## Run tests for this plugin

To run both the tests, and code style validation, run

```
bundle exec rake
```

To automatically fix many of the styling issues, use
```
bundle exec rake rubocop:autocorrect
```

You can check other useful tasks by running

```
bundle exec rake -T
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to [this repository](https://github.com/manicmaniac/fastlane-plugin-sync_devices).

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
