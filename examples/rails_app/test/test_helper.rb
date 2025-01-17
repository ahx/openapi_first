ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

require 'openapi_first'
OpenapiFirst::Test.register(Rails.root.join('../../spec/data/train-travel-api/openapi.yaml'))
OpenapiFirst::Test.register(Rails.root.join('../../spec/data/attachments_openapi.yaml'), as: :attachments)

OpenapiFirst::Test::Coverage.register(
  Rails.root.join('../../spec/data/train-travel-api/openapi.yaml'),
  Rails.root.join('../../spec/data/attachments_openapi.yaml')
)
OpenapiFirst::Test::Coverage.start

Minitest.after_run do
  OpenapiFirst::Test::Coverage.report
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Add more helper methods to be used by all tests here...
  end
end

TEST_APP = OpenapiFirst::Test.app(TrainTravel::Application, spec: Rails.root.join('../../spec/data/attachments_openapi.yaml'))

module ActionDispatch
  class IntegrationTest
    def app
      TEST_APP
    end
  end
end
