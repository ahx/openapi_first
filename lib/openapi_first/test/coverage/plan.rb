# frozen_string_literal: true

require_relative 'route_task'
require_relative 'response_task'
require_relative 'request_task'

module OpenapiFirst
  module Test
    module Coverage
      # This stores the coverage data for one API description
      # A plan can be #done? and has several #tasks which can be #finished?
      class Plan
        class UnknownRequestError < StandardError; end

        def initialize(oad)
          @oad = oad
          @routes = []
          @index = {}
          @filepath = oad.filepath
          oad.routes.each do |route|
            add_route request_method: route.request_method,
                      path: route.path,
                      requests: route.requests,
                      responses: route.responses
          end
        end

        attr_reader :filepath, :oad, :routes
        private attr_reader :index

        def track_request(validated_request)
          index[validated_request.request_definition.key].track(validated_request) if validated_request.known?
        end

        def track_response(validated_response)
          index[validated_response.response_definition.key].track(validated_response) if validated_response.known?
        end

        def done?
          tasks.all?(&:finished?)
        end

        def coverage
          done = tasks.count(&:finished?)
          return 0 if done.zero?

          all = tasks.count
          (done / (all.to_f / 100)).to_i
        end

        def tasks
          index.values
        end

        private

        def add_route(request_method:, path:, requests:, responses:)
          request_tasks = requests.to_a.map do |request|
            index[request.key] = RequestTask.new(request)
          end
          response_tasks = responses.to_a.map do |response|
            index[response.key] = ResponseTask.new(response)
          end
          @routes << RouteTask.new(path:, request_method:, requests: request_tasks, responses: response_tasks)
        end
      end
    end
  end
end
