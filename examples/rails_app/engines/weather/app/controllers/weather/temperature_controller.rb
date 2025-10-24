module Weather
  class TemperatureController < ApplicationController
    def index
      render json: {
        latitude:, longitude:, temperature: {
          celsius: "11.94",
          fahenheit: "53.5"
        }
      }
    end

    private

    def latitude = params.require(:latitude)
    def longitude = params.require(:longitude)
  end
end
