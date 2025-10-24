# frozen_string_literal: true

require "test_helper"

class Weather::TemperatureControllerTest < ActionDispatch::IntegrationTest
  test "it returns temperature data for given latitude and longitude" do
    get weather_engine.temperature_path, params: { latitude: "37.7749", longitude: "-122.4194" }

    assert_response :success
    json_response = JSON.parse(response.body)

    assert_equal "37.7749", json_response["latitude"]
    assert_equal "-122.4194", json_response["longitude"]
    assert_equal "11.94", json_response["temperature"]["celsius"]
    assert_equal "53.5", json_response["temperature"]["fahenheit"]
  end
end
