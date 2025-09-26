# frozen_string_literal: true

require_relative 'coverage/plan'
require_relative 'coverage/tracker'
require_relative 'coverage/covered_request'
require_relative 'coverage/covered_response'
require 'drb'

module OpenapiFirst
  module Test
    # The Coverage module is about tracking request and response validation
    # to assess if all parts of the API description have been tested.
    # Currently it does not care about unknown requests that are not part of any API description.
    module Coverage
      autoload :TerminalFormatter, 'openapi_first/test/coverage/terminal_formatter'

      Result = Data.define(:plans, :coverage)

      class << self
        # @visibility private
        def install
          raise NoMethodError, 'Coverage.install was removed. Please use Test.setup instead'
        end

        def start(skip_response: nil, skip_route: nil)
          tracker = Tracker.new(Test.definitions, skip_response:, skip_route:)

          # We need a custom DRbServer (not using DRb.start_service) because otherwise
          # we'd conflict with Rails's DRb server
          @drb_uri = DRb::DRbServer.new(nil, tracker).uri
        end

        # @visibility private
        def uninstall
          raise NoMethodError, 'Coverage.uninstall was removed. Please use Test.uninstall instead'
        end

        # Clear current coverage run
        def reset
          @tracker = nil

          return unless @drb_uri

          service = DRb.fetch_server(@drb_uri)
          service&.stop_service
          @drb_uri = nil
        end

        def track_request(request, oad)
          return unless request.known?

          # The call to `track_request` may happen remotely in the main process that started
          # the coverage collection.
          # To make this work we need to keep arguments trivial, which is the reason the request
          # is wrapped in a CoveredRequest data object.
          tracker&.track_request(
            oad.key,
            CoveredRequest.new(
              key: request.request_definition.key,
              error: request.error
            )
          )
        end

        def track_response(response, _request, oad)
          return unless response.known?

          # The call to `track_response` may happen remotely in the main process that started
          # the coverage collection.
          # To make this work we need to keep arguments trivial, which is the reason the response
          # is wrapped in a CoveredResponse data object.
          tracker&.track_response(
            oad.key,
            CoveredResponse.new(
              key: response.response_definition.key,
              error: response.error
            )
          )
        end

        def result
          Result.new(plans:, coverage:)
        end

        private

        def current_run
          tracker.plans_by_key
        end

        # Returns all plans (Plan) that were registered for this run
        def plans
          tracker&.plans || []
        end

        def tracker
          return unless @drb_uri

          @tracker ||= DRbObject.new_with_uri(@drb_uri)
        end

        def coverage
          return 0 if plans.empty?

          plans.sum(&:coverage) / plans.length
        end
      end
    end
  end
end
