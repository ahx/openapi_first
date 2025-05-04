require 'test_helper'

class TripsApiTest < ActionDispatch::IntegrationTest
  test 'GET /trips' do
    get '/trips',
        params: { origin: 'efdbb9d1-02c2-4bc3-afb7-6788d8782b1e', destination: 'b2e783e1-c824-4d63-b37a-d8d698862f1d',
                  date: '2024-07-02T09:00:00Z' }

    assert_api_conform(status: 200)
  end
end
