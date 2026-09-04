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

          attr_reader :coverage, :plans, :verbose, :generated_at,
                      :skipped_requests_count, :skipped_responses_count

          def initialize(coverage_result, verbose, generated_at: Time.now)
            @coverage = coverage_result.coverage
            @plans = coverage_result.plans
            @skipped_requests_count = coverage_result.skipped_requests_count
            @skipped_responses_count = coverage_result.skipped_responses_count
            @verbose = verbose
            @generated_at = generated_at.strftime('%Y-%m-%d %H:%M:%S %z')
          end

          # Helper for ERB rendering only — exposes this context's binding so the
          # template can resolve helper methods and instance state.
          def get_binding # rubocop:disable Naming/AccessorMethodName
            binding
          end

          def any_skipped?
            skipped_requests_count.positive? || skipped_responses_count.positive?
          end

          def visible_routes(plan)
            plan.routes
          end

          def any_request_made?(route)
            route.requests.any?(&:requested?)
          end

          def route_status(route)
            return :skipped if route.skipped?
            return :request_problem if route.tracked_requests.none?(&:finished?)
            return :responses_problem if any_request_made?(route) && route.tracked_responses.any? { |r| !r.finished? }

            :ok
          end

          def route_class(route)
            return 'is-skipped' if route.skipped?

            route.finished? ? 'is-covered' : 'is-uncovered'
          end

          def uncovered_responses_count(route)
            route.tracked_responses.count { |r| !r.finished? }
          end

          def request_items(route)
            return route.requests if route.skipped?
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
