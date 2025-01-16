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

  config.after do
    OpenapiFirst::Test::DEFINITIONS.clear
  end
end
