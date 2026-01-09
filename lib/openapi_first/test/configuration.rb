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
        @skip_coverage = nil
        @response_raise_error = true
        @ignored_unknown_status = Set.new([401, 404, 500])
        @ignore_unknown_response_status = false
        @report_coverage = true
        @ignore_unknown_requests = false
        @ignore_request_error = nil
        @ignore_response_error = nil
      end

      # Register OADs, but don't load them just yet
      # @param [OpenapiFirst::OAD] oad The OAD to register
      # @param [Symbol] as The name to register the OAD under
      def register(oad, as: :default)
        Test.register(oad, as:)
      end

      # Observe a rack app
      def observe(app, api: :default)
        Observe.observe(app, api:)
      end

      attr_accessor :coverage_formatter_options, :coverage_formatter, :response_raise_error,
                    :ignore_unknown_requests, :ignore_unknown_response_status, :minimum_coverage
      attr_reader :report_coverage, :ignored_unknown_status

      # Set ignored unknown status codes.
      # @param [Array<Integer>] status Status codes that are okay not to cover in an OAD
      def ignored_unknown_status=(status)
        @ignored_unknown_status = status.to_set
      end

      # Configure report coverage
      # @param [Boolean, :warn] value Whether to report coverage or just warn.
      def report_coverage=(value)
        allowed_values = [true, false, :warn]
        unless allowed_values.include?(value)
          raise ArgumentError, "'report_coverage' must be one of #{allowed_values}, but was #{value.inspect}"
        end

        @report_coverage = value
      end

      # Ignore certain errors for certain requests
      # @param block A Proc that will be called with [OpenapiFirst::ValidatedRequest]
      def ignore_request_error(&block)
        raise ArgumentError, 'You have to pass a block' unless block_given?

        @ignore_request_error = block
      end

      # Ignore certain errors for certain responses
      # @param block A Proc that will be called with [OpenapiFirst::ValidatedResponse, Rack::Request]
      def ignore_response_error(&block)
        raise ArgumentError, 'You have to pass a block' unless block_given?

        @ignore_response_error = block
      end

      # @param block A Proc that will be called with [OpenapiFirst::ValidatedResponse, Rack::Request]
      def skip_response_coverage(&block)
        return @skip_response_coverage unless block_given?

        @skip_response_coverage = block
      end

      def skip_coverage(&block)
        return @skip_coverage unless block_given?

        @skip_coverage = block
      end

      alias ignore_unknown_response_status? ignore_unknown_response_status
      alias ignore_unknown_requests? ignore_unknown_requests

      def raise_request_error?(validated_request)
        return false if @ignore_request_error&.call(validated_request)
        return false if ignore_unknown_requests? && validated_request.unknown?

        true
      end

      def raise_response_error?(validated_response, rack_request)
        return false if @ignore_response_error&.call(validated_response, rack_request)
        return false if response_raise_error == false
        return false if ignored_unknown_status.include?(validated_response.status)
        return false if ignore_unknown_response_status? && validated_response.error.type == :response_status_not_found

        true
      end
    end
  end
end
