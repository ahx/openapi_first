# frozen_string_literal: true

module OpenapiFirst
  module Test
    module Coverage
      RouteTask = Data.define(:path, :request_method, :requests, :responses) do
        def finished?
          requests.all?(&:finished?) && responses.all?(&:finished?)
        end
      end
    end
  end
end
