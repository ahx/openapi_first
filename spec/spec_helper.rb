# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'bundler/setup'
require 'openapi_first'
require 'json'
require 'simplecov'
require 'rack/test'

SimpleCov.start do
  enable_coverage :branch
  primary_coverage :branch
  add_filter 'lib/openapi_first/test/coverage/'
end

SimpleCov.minimum_coverage line: 99, branch: 85

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after(:each) do
    OpenapiFirst::Test.definitions.clear
    OpenapiFirst.definitions.clear
    OpenapiFirst::Test.uninstall
    OpenapiFirst::Test::Coverage.reset
  end
end
