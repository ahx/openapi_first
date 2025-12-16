# frozen_string_literal: true

require_relative 'test/configuration'
require_relative 'registry'

module OpenapiFirst
  # Test integration
  module Test # rubocop:disable Metrics/ModuleLength
    autoload :Coverage, 'openapi_first/test/coverage'
    autoload :Methods, 'openapi_first/test/methods'
    autoload :Observe, 'openapi_first/test/observe'
    autoload :App, 'openapi_first/test/app'
    extend Registry

    class CoverageError < Error; end
    class UnknownQueryParameterError < Error; end

    # Inject request/response validation in a rack app class
    def self.observe(app, api: :default)
      Observe.observe(app, api:)
    end

    def self.minitest?(base)
      base.include?(::Minitest::Assertions)
    rescue NameError
      false
    end

    def self.definitions
      super.empty? ? OpenapiFirst.definitions : super
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.registered?(oad)
      key = oad.key
      definitions.any? { |(_name, registered)| registered.key == key }
    end

    # Sets up OpenAPI test coverage and OAD registration.
    # @yieldparam [OpenapiFirst::Test::Configuration] configuration A configuration to setup test integration
    def self.setup
      install
      yield configuration if block_given?

      Coverage.start(skip_response: configuration.skip_response_coverage, skip_route: configuration.skip_coverage)

      if definitions.empty?
        raise NotRegisteredError,
              'No API descriptions have been registered. ' \
              'Please register your API description via ' \
              "`OpenapiFirst.register('myopenapi.yaml)` or " \
              'in a block passed to `OpenapiFirst::Test.setup` like this: ' \
              "`OpenapiFirst::Test.setup { |test| test.register('myopenapi.yaml') }` " \

      end

      @exit_handler = method(:handle_exit)

      main_process = Process.pid
      @setup ||= at_exit do
        # :nocov:
        # Only handle exit once in the main process
        @exit_handler&.call if Process.pid == main_process
        # :nocov:
      end
    end

    def self.handle_exit
      return unless configuration.report_coverage

      report_coverage(
        formatter: configuration.coverage_formatter,
        **configuration.coverage_formatter_options
      )
      return unless configuration.report_coverage == true

      coverage = Coverage.result.coverage
      return if coverage >= configuration.minimum_coverage

      puts "API Coverage fails with exit 2, because not all described requests and responses have been tested (#{coverage.round(4)}% covered)." # rubocop:disable Layout/LineLength

      exit 2
    end

    # Print the coverage report
    # @param formatter A formatter to define the report.
    # @output [IO] An output where to puts the report.
    def self.report_coverage(formatter: Coverage::TerminalFormatter, **)
      puts formatter.new(**).format(Coverage.result)
    end

    # Returns the Rack app wrapped with silent request, response validation
    # You can use this if you want to track coverage via Test::Coverage, but don't want to use
    # the middlewares or manual request, response validation.
    def self.app(app, spec: nil, api: :default, validate_request_after_handling: false)
      spec ||= self[api]
      App.new(app, api: spec, validate_request_after_handling:)
    end

    def self.install
      return if @installed

      OpenapiFirst.configure do |config|
        @after_request_validation = config.after_request_validation do |validated_request, oad|
          next unless registered?(oad)
          raise validated_request.error.exception if raise_request_error?(validated_request)

          check_unknown_query_parameters(validated_request)

          Coverage.track_request(validated_request, oad)
        end

        @after_response_validation = config.after_response_validation do |validated_response, rack_request, oad|
          next unless registered?(oad)
          if validated_response.invalid? && raise_response_error?(validated_response)
            raise validated_response.error.exception
          end

          Coverage.track_response(validated_response, rack_request, oad)
        end
      end
      @installed = true
    end

    def self.uninstall
      configuration = OpenapiFirst.configuration
      configuration.after_request_validation.delete(@after_request_validation)
      configuration.after_response_validation.delete(@after_response_validation)
      definitions.clear
      @configuration = nil
      @installed = nil
      @exit_handler = nil
    end

    class << self
      private

      def check_unknown_query_parameters(validated_request)
        return unless validated_request.known?

        unknown_parameters = validated_request.unknown_query_parameters
        return unless unknown_parameters

        message = unknown_parameters_message(unknown_parameters, validated_request)
        raise UnknownQueryParameterError, message
      end

      def unknown_parameters_message(unknown_parameters, validated_request)
        s = 's' if many?(unknown_parameters)
        list = unknown_parameters.keys.map(&:inspect).join(', ')
        "Unknown query parameter#{s} #{list} for #{validated_request.fullpath}"
      end

      def raise_request_error?(validated_request)
        return false if validated_request.valid?
        return false if validated_request.known?

        !configuration.ignore_unknown_requests
      end

      def many?(array) = array.length > 1

      def raise_response_error?(invalid_response)
        configuration.response_raise_error && !configuration.ignore_response?(invalid_response)
      end
    end
  end
end
