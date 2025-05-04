# frozen_string_literal: true

require 'test_helper'

class StationsApiTest < ActionDispatch::IntegrationTest
  test 'GET /stations' do
    get '/stations'

    assert_api_conform(status: 200)
  end
end
