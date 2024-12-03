# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'bundler/setup'
require 'openapi_first'
require 'multi_json'
require 'simplecov'
require 'rack/test'

SimpleCov.start do
  enable_coverage :branch
  primary_coverage :branch
end

SimpleCov.minimum_coverage line: 99, branch: 85

module OpenapiFirstSpecHelpers
  def json_dump(data)
    MultiJson.dump(data)
  end

  def json_load(string, symbolize_keys: false)
    MultiJson.load(string, { symbolize_keys: })
  end
end

RSpec.configure do |config|
  config.include(OpenapiFirstSpecHelpers)

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
