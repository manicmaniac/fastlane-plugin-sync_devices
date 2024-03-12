source('https://rubygems.org')

gem 'bundler'
gem 'debug', '>= 1.0'
gem 'fastlane', '>= 2.219.0'
gem 'guard'
gem 'guard-rspec'
gem 'guard-rubocop'
gem 'pry'
gem 'rackup'
gem 'rake'
gem 'rspec'
gem 'rubocop', '1.50.2'
gem 'rubocop-performance'
gem 'rubocop-require_tools'
gem 'rubocop-rspec'
gem 'simplecov'
gem 'sinatra', '~> 4.0'
gem 'webrick'

gemspec

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
