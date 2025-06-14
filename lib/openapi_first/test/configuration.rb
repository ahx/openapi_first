# frozen_string_literal: true

module OpenapiFirst
  module Test
    # Helper class to setup tests
    class Configuration
      def initialize
        @minimum_coverage = 100
        @coverage_formatter = Coverage::TerminalFormatter
        @coverage_formatter_options = {}
        @skip_response_coverage = nil
        @response_raise_error = true
        @ignored_unknown_status = []
        @report_coverage = true
        @registry = {}
      end

      # Register OADs, but don't load them just yet
      def register(oad, as: :default)
        @registry[as] = oad
      end

      attr_accessor :coverage_formatter_options, :coverage_formatter, :response_raise_error
      attr_reader :registry, :minimum_coverage, :report_coverage, :ignored_unknown_status

      def minimum_coverage=(value)
        warn 'Setting OpenapiFirst::Test::Configuration#minimum_coverage= is deprecated ' \
             'and will be removed in a future version.' \
             "Use 'report_coverage = true / false / :info' instead."
        @minimum_coverage = value
      end

      def report_coverage=(value)
        allowed_values = [true, false, :warn]
        unless allowed_values.include?(value)
          raise ArgumentError, "'report_coverage' must be one of #{allowed_values}, but was #{value.inspect}"
        end

        @report_coverage = value
      end

      def skip_response_coverage_if(&block)
        return @skip_response_coverage unless block_given?

        @skip_response_coverage = block
      end

      # TODO: Deprecate skip_response_coverage
      alias skip_response_coverage skip_response_coverage_if
    end
  end
end
