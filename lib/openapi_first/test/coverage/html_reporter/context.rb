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

          attr_reader :coverage, :plans, :verbose

          def initialize(coverage_result, verbose)
            @coverage = coverage_result.coverage
            @plans = coverage_result.plans
            @verbose = verbose
          end

          # Helper for ERB rendering only — exposes this context's binding so the
          # template can resolve helper methods and instance state.
          def get_binding # rubocop:disable Naming/AccessorMethodName
            binding
          end

          def plan_identifier(plan)
            plan.api_identifier.to_s.delete_prefix("#{Dir.pwd}/")
          end

          # Render every row of a plan, even covered ones, when the user asked for
          # verbose output or when the plan is fully covered (and collapsing would
          # hide nothing useful).
          def expand_plan?(plan)
            verbose || plan.done?
          end

          # Routes worth rendering for `plan` — drops finished routes unless the
          # plan is being expanded.
          def visible_routes(plan)
            return plan.routes if expand_plan?(plan)

            plan.routes.reject(&:finished?)
          end

          # Whether any request on `route` was actually observed during the run.
          def any_request_made?(route)
            route.requests.any?(&:requested?)
          end

          # Coarse status for the route summary badge:
          #   :request_problem   – no request was successfully validated
          #   :responses_problem – requests succeeded but some responses are uncovered
          #   :ok                – nothing to flag
          def route_status(route)
            return :request_problem if route.requests.none?(&:finished?)
            return :responses_problem if any_request_made?(route) && route.responses.any? { |r| !r.finished? }

            :ok
          end

          def uncovered_responses_count(route)
            route.responses.count { |r| !r.finished? }
          end

          # Request rows to render for `route`, given whether the plan is expanded.
          # Empty unless at least one request was made and at least one request
          # definition has a content type to display.
          def request_items(route, plan_verbose:)
            return [] unless any_request_made?(route) && route.requests.any?(&:content_type)

            plan_verbose ? route.requests : route.requests.reject(&:finished?)
          end

          # Response rows to render for `route`. Skipped entirely when no request
          # was made (and the plan is not expanded), since a "no responses tracked"
          # list under an unrequested route is just noise.
          def response_items(route, plan_verbose:)
            return [] unless plan_verbose || any_request_made?(route)

            plan_verbose ? route.responses : route.responses.reject(&:finished?)
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
