# frozen_string_literal: true

require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

require 'yard'
YARD::Rake::YardocTask.new

task(default: %i[spec rubocop])

file 'spec/support/fixtures/api_key.json' do |task|
  require 'json'
  require 'openssl'

  json = JSON.pretty_generate(
    {
      key_id: 'TEST',
      issuer_id: 'TEST',
      key: OpenSSL::PKey::EC.generate('prime256v1').export.chomp,
      duration: 500,
      in_house: false
    }
  )
  File.write(task.name, json)
end

file 'spec/support/fixtures/system/0.tsv' do |task|
  require_relative 'spec/support/helpers/device_helper'

  include DeviceHelper

  File.open(task.name, 'w') do |f|
    f.puts("Device ID\tDevice Name\tDevice Platform")
    20.times do
      f.puts(random_device_tsv_row)
    end
  end
end

file 'spec/support/fixtures/system/1.tsv' => 'spec/support/fixtures/system/0.tsv' do |task|
  require 'csv'
  require_relative 'spec/support/helpers/device_helper'

  include DeviceHelper

  csv = CSV.read(task.source, col_sep: "\t")
  new_csv_string = CSV.generate(col_sep: "\t") do |new_csv|
    csv.each_with_index do |row, index|
      case index % 3
      when 0 # as-is
        new_csv << row
      when 1 # rename
        row[1] = random_name
        new_csv << row
      when 2 # disable
        next
      end
    end
  end
  new_csv_string += (0..(csv.size / 3)).map { "#{random_device_tsv_row}\n" }.join
  File.write(task.name, new_csv_string)
end
