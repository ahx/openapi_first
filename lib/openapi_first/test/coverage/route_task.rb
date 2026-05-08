# frozen_string_literal: true

module OpenapiFirst
  module Test
    module Coverage
      RouteTask = Data.define(:path, :request_method, :requests, :responses) do
        def finished?
          requests.all?(&:finished?) && responses.all?(&:finished?)
        end

        def summary
          operation = requests.first&.request&.operation
          operation&.[]('summary') || operation&.[]('description')
        end
      end
    end
  end
end
