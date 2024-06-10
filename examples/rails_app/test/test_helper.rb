ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

require 'openapi_first/test'
OpenapiFirst::Test.register(Rails.root.join('../../spec/data/train-travel-api/openapi.yaml'))

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Add more helper methods to be used by all tests here...
  end
end
