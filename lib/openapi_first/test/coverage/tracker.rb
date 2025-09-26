# frozen_string_literal: true

module OpenapiFirst
  module Test
    module Coverage
      # Class that allows tracking requests and response for OAD definitions.
      # For each definition it builds a plan and forwards tracking to the correct plan.
      class Tracker
        attr_reader :plans_by_key

        def initialize(definitions, skip_response: nil, skip_route: nil)
          @plans_by_key = definitions.values.to_h do |oad|
            plan = Plan.for(oad, skip_response:, skip_route:)
            [oad.key, plan]
          end
        end

        def track_request(key, request)
          @plans_by_key[key]&.track_request(request)
        end

        def track_response(key, response)
          @plans_by_key[key]&.track_response(response)
        end

        def plans
          @plans_by_key.values
        end
      end
    end
  end
end
