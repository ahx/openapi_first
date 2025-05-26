# frozen_string_literal: true

module OpenapiFirst
  module Test
    # Helper class to setup tests
    class Configuration
      def initialize
        @minimum_coverage = 0
        @coverage_formatter = Coverage::TerminalFormatter
        @coverage_formatter_options = {}
        @skip_response_coverage = nil
        @response_raise_error = true
        @registry = {}
        yield self if block_given?
      end

      # Register OADs, but don't load them just yet
      def register(oad, as: :default)
        @registry[as] = oad
      end

      attr_accessor :minimum_coverage, :coverage_formatter_options, :coverage_formatter, :response_raise_error
      attr_reader :registry

      def skip_response_coverage_if(&block)
        return @skip_response_coverage unless block_given?

        @skip_response_coverage = block
      end

      # TODO: Deprecate skip_response_coverage
      alias skip_response_coverage skip_response_coverage_if

      # This called at_exit
      def handle_exit
        coverage = Coverage.result.coverage
        # :nocov:
        puts 'API Coverage did not detect any API requests for the registered API descriptions' if coverage.zero?
        if coverage.positive?
          Test.report_coverage(
            formatter: coverage_formatter,
            **coverage_formatter_options
          )
        end
        return unless minimum_coverage > coverage

        puts "API Coverage fails with exit 2, because API coverage of #{coverage}% " \
             "is below minimum of #{minimum_coverage}%!"
        exit 2
        # :nocov:
      end
    end
  end
end
