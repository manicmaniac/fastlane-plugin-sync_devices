source('https://rubygems.org')

gem 'bundler'
gem 'fastlane', '>= 2.219.0'
gem 'guard'
gem 'guard-rspec'
gem 'guard-rubocop'
gem 'pry'
gem 'rake'
gem 'rspec'
gem 'rubocop', '1.50.2'
gem 'rubocop-performance'
gem 'rubocop-require_tools'
gem 'rubocop-rspec'
gem 'simplecov'

gemspec

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
