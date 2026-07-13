# frozen_string_literal: true

require 'erb'

module OpenapiFirst
  module Test
    module Coverage
      class HtmlReporter
        # Provides the binding and helper methods for the ERB template.
        class Context
          NO_REQUESTS_WARNING =
            'API Coverage did not detect any API requests for the registered ' \
            'API descriptions. Make sure to observe your application using OpenapiFirst::Test.'

          attr_reader :coverage, :plans, :verbose, :generated_at

          def initialize(coverage_result, verbose, generated_at: Time.now)
            @coverage = coverage_result.coverage
            @plans = coverage_result.plans
            @verbose = verbose
            @generated_at = generated_at.strftime('%Y-%m-%d %H:%M:%S %z')
          end

          # Helper for ERB rendering only — exposes this context's binding so the
          # template can resolve helper methods and instance state.
          def get_binding # rubocop:disable Naming/AccessorMethodName
            binding
          end

          def visible_routes(plan)
            plan.routes
          end

          def any_request_made?(route)
            route.requests.any?(&:requested?)
          end

          def route_status(route)
            return :request_problem if route.requests.none?(&:finished?)
            return :responses_problem if any_request_made?(route) && route.responses.any? { |r| !r.finished? }

            :ok
          end

          def uncovered_responses_count(route)
            route.responses.count { |r| !r.finished? }
          end

          def request_items(route)
            return [] unless any_request_made?(route) && route.requests.any?(&:content_type)

            route.requests
          end

          def response_items(route)
            route.responses
          end

          def h(text)
            ERB::Util.html_escape(text)
          end

          def explain_unfinished_request(request)
            return 'No requests tracked!' unless request.requested?
            return if request.any_valid_request?

            "All requests invalid! (#{request.last_error_message.inspect})"
          end

          def explain_unfinished_response(response, request_made: false)
            unless response.responded?
              return request_made ? 'No matching response tracked!' : 'No responses tracked!'
            end

            "All responses invalid! (#{response.last_error_message.inspect})" unless response.any_valid_response?
          end
        end
      end
    end
  end
end
