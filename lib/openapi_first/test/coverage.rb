# frozen_string_literal: true

require_relative 'coverage/plan'
require_relative 'coverage/terminal_formatter'

module OpenapiFirst
  module Test
    # The Coverage module is about tracking request and response validation
    # to assess if all parts of the API description have been tested.
    # Currently it does not care about unknown requests that are not part of any API description.
    module Coverage
      # @visibility private
      class NotRegisteredError < StandardError; end

      # @visibility private
      class Configuration
        def initialize
          @output = $stdout
        end

        attr_accessor :output
      end

      @registry = Hash.new do |_, filepath|
        raise NotRegisteredError,
              "API description '#{filepath}' was not registered." \
              "Please call OpenapiFirst::Coverage.register('path/to/myopenapi.yaml') before calling" \
              'OpenapiFirst::Coverage.start making requests.' \
              "Registered descriptions are: #{plans.map(&:filepath)}."
      end

      @output = $stdout

      class << self
        attr_reader :registry
        private attr_writer :output

        def start
          configuration = Configuration.new.clone
          yield configuration if block_given?

          self.output = configuration.output
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

        # Add OAD where coverage should be tracked.
        def register(*filepaths)
          filepaths.each do |filepath|
            oad = OpenapiFirst.load(filepath)
            registry[oad.filepath] = oad
          end
        end

        # Remove all OADs from registry.
        def reset
          @current_run = nil
        end

        def track_request(request, oad)
          current_run[oad.filepath].track_request(request)
        end

        def track_response(response, _request, oad)
          current_run[oad.filepath].track_response(response)
        end

        # Print the coverage report
        # @param formatter A formatter to define the report.
        # @output [IO] An output where to puts the report.
        def report(formatter: TerminalFormatter, output: $stdout)
          output.puts formatter.new.format(plans)
        end

        # Returns all plans (Plan) that were registered for this run
        def plans
          current_run.values
        end

        private

        def current_run
          @current_run ||= registry.transform_values do |oad|
            Plan.new(oad)
          end
        end
      end
    end
  end
end
