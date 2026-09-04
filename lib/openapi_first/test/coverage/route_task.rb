# frozen_string_literal: true

module OpenapiFirst
  module Test
    module Coverage
      RouteTask = Data.define(:path, :request_method, :requests, :responses) do
        def skipped?
          requests.all?(&:skipped?)
        end

        def tracked_requests
          requests.reject(&:skipped?)
        end

        def tracked_responses
          responses.reject(&:skipped?)
        end

        def skipped_requests
          requests.select(&:skipped?)
        end

        def skipped_responses
          responses.select(&:skipped?)
        end

        def finished?
          return false if skipped?

          tracked_requests.all?(&:finished?) && tracked_responses.all?(&:finished?)
        end

        def summary
          operation = requests.first&.request&.operation
          operation&.[]('summary') || operation&.[]('description')
        end
      end
    end
  end
end
