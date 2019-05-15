# frozen_string_literal: true

require 'bundler/setup'
require 'openapi_first'
require 'multi_json'

module OpenapiFirstSpecHelpers
  def find_operation(spec, path, method)
    spec.path_by_path(path).endpoint_by_method(method.to_s.downcase)
  end

  def json_dump(data)
    MultiJson.dump(data)
  end

  def json_load(string, options = {})
    MultiJson.load(string, options)
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
