# frozen_string_literal: true

require 'test_helper'

class StationsApiTest < ActionDispatch::IntegrationTest
  include OpenapiFirst::Test::Methods

  test 'GET /attachments/{attachment_id}' do
    get '/attachments/42abc', as: :json
    assert_api_conform(status: 200, api: :attachments)
  end
end
