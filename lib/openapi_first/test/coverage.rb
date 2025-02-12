# frozen_string_literal: true

require_relative 'coverage/plan'

module OpenapiFirst
  module Test
    # The Coverage module is about tracking request and response validation
    # to assess if all parts of the API description have been tested.
    # Currently it does not care about unknown requests that are not part of any API description.
    module Coverage
      autoload :TerminalFormatter, 'openapi_first/test/coverage/terminal_formatter'

      Result = Data.define(:plans, :coverage)

      class << self
        def start
          @after_request_validation = lambda do |validated_request, oad|
            track_request(validated_request, oad)
          end

          @after_response_validation = lambda do |validated_response, request, oad|
            track_response(validated_response, request, oad)
          end

          OpenapiFirst.configure do |config|
            config.after_request_validation(&@after_request_validation)
            config.after_response_validation(&@after_response_validation)
          end
        end

        def stop
          configuration = OpenapiFirst.configuration
          configuration.hooks[:after_request_validation].delete(@after_request_validation)
          configuration.hooks[:after_response_validation].delete(@after_response_validation)
        end

        # Clear current coverage run
        def reset
          @current_run = nil
        end

        def track_request(request, oad)
          current_run[oad.filepath].track_request(request)
        end

        def track_response(response, _request, oad)
          current_run[oad.filepath].track_response(response)
        end

        def result
          Result.new(plans:, coverage:)
        end

        private

        # Returns all plans (Plan) that were registered for this run
        def plans
          current_run.values
        end

        def coverage
          return 0 if plans.empty?

          plans.sum(&:coverage) / plans.length
        end

        def current_run
          @current_run ||= Test.definitions.values.to_h do |oad|
            [oad.filepath, Plan.new(oad)]
          end
        end
      end
    end
  end
end
