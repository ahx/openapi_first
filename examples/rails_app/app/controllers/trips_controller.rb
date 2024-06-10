class TripsController < ApplicationController
  def index
    render json: {
      data: [{ id: 'efdbb9d1-02c2-4bc3-afb7-6788d8782b1e' }]
    }
  end
end
