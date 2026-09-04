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

        def self.for(oad, skip_response: nil, skip_route: nil)
          plan = new(definition_key: oad.key, filepath: oad.filepath, title: oad.title)
          oad.routes.each do |route|
            plan.add_route request_method: route.request_method,
                           path: route.path,
                           requests: route.requests,
                           responses: route.responses,
                           skipped: skip_route ? skip_route[route.path, route.request_method] : false,
                           skip_response:
          end
          plan
        end

        def initialize(definition_key:, filepath: nil, title: nil)
          @routes = []
          @index = {}
          @api_identifier = filepath || definition_key
          @filepath = filepath
          @title = title
        end

        attr_reader :api_identifier, :filepath, :routes, :title
        private attr_reader :index

        def track_request(validated_request)
          index[validated_request.key]&.track(validated_request)
        end

        def track_response(validated_response)
          index[validated_response.key]&.track(validated_response)
        end

        def done?
          tasks.all?(&:finished?)
        end

        def coverage
          done = tasks.count(&:finished?)
          return 0 if done.zero?

          all = tasks.count
          return 100 if done == all

          (done / (all.to_f / 100))
        end

        def tasks
          index.values
        end

        def skipped_requests
          routes.flat_map(&:skipped_requests)
        end

        def skipped_responses
          routes.flat_map(&:skipped_responses)
        end

        def skipped_requests_count
          skipped_requests.count
        end

        def skipped_responses_count
          skipped_responses.count
        end

        def add_route(request_method:, path:, requests:, responses:, skipped: false, skip_response: nil)
          request_tasks = requests.to_a.map { |request| add_task RequestTask.new(request, skipped:) }
          response_tasks = responses.to_a.map do |response|
            add_task ResponseTask.new(response, skipped: skipped || (skip_response ? skip_response[response] : false))
          end
          @routes << RouteTask.new(path:, request_method:, requests: request_tasks, responses: response_tasks)
        end

        private

        def add_task(task)
          index[task.key] = task unless task.skipped?
          task
        end
      end
    end
  end
end
