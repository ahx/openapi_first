# frozen_string_literal: true

require 'test_helper'

class AttachmentsApiTest < ActionDispatch::IntegrationTest
  # def openapi_first_default_api = :attachments
  include OpenapiFirst::Test::Methods[TrainTravel::Application, api: :attachments]

  test 'GET /attachments/{attachment_id}' do
    get '/attachments/42abc', as: :json

    assert_api_conform(status: 200)
  end
end
