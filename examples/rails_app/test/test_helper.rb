ENV['RAILS_ENV'] ||= 'test'

require_relative '../config/environment'
require 'rails/test_help'

require 'openapi_first'
OpenapiFirst::Test.setup do |test|
  test.register Rails.root.join('../../spec/data/train-travel-api/openapi.yaml')
  test.register Rails.root.join('../../spec/data/attachments_openapi.yaml'), as: :attachments
  test.coverage_formatter_options = { verbose: true }
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Add more helper methods to be used by all tests here...
  end
end


module ActionDispatch
  class IntegrationTest
    include OpenapiFirst::Test::Methods[TrainTravel::Application]
  end
end
