# frozen_string_literal: true

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
          @index = {}
          @filepath = oad.filepath
          oad.routes.each do |route|
            route.requests.each do |request|
              add request:, responses: route.responses.to_a
            end
          end
        end

        attr_reader :filepath, :oad
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

        def requests
          tasks.filter(&:request?)
        end

        def tasks
          index.values
        end

        def coverage
          done = tasks.count(&:finished?)
          return 0 if done.zero?

          all = tasks.count
          (done / (all.to_f / 100)).to_i
        end

        private

        def add(request:, responses:)
          response_tasks = responses.map do |response|
            ResponseTask.new(response)
          end
          index[request.key] = RequestTask.new(request, responses: response_tasks)
          response_tasks.each do |task|
            index[task.key] = task
          end
        end
      end
    end
  end
end
