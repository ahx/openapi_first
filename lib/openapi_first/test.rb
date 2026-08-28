# frozen_string_literal: true

require 'logger'
require_relative 'test/configuration'
require_relative 'registry'

module OpenapiFirst
  # Test integration for contract testing. Use this to validate requests/responses against a
  # registered OAD while your test suite runs, and tracks which parts of the API
  # description have been exercised.
  #
  # @example Basic setup (e.g. in spec_helper.rb)
  #   require 'openapi_first'
  #   OpenapiFirst::Test.setup
  #
  # {.setup} prepares coverage tracking and OAD registration. To actually validate the
  # requests/responses that happen during your tests, you also have to observe your
  # application, i.e. wrap it with silent request/response validation. There are three ways
  # to do this:
  #
  # 1. Include {Methods}, which adds an `app` method wrapping your rack app for rack-test.
  #    This is the easiest option if you don't already define `app` yourself:
  #      RSpec.configure do |config|
  #        config.include OpenapiFirst::Test::Methods[MyApp], type: :request
  #      end
  # 2. Call {.observe} to inject validation directly into an app class or instance
  #    , if you can't rely on rack-test's `app` method:
  #      OpenapiFirst::Test.observe(Rails.application)
  # 3. Call {.app} to wrap an app instance yourself, e.g. if you already define your own
  #    `app` method and only want to wrap what it returns:
  #      def app
  #        OpenapiFirst::Test.app(MyApp.new)
  #      end
  #
  # @example Configure via the block passed to .setup
  #   OpenapiFirst::Test.setup do |test|
  #     test.register('openapi/openapi.yaml')
  #
  #     # Ignore certain request/response errors instead of raising them
  #     test.ignore_request_error do |validated_request|
  #       validated_request.path.start_with?('/legacy') && validated_request.unknown?
  #     end
  #     test.ignore_response_error do |validated_response, rack_request|
  #       validated_response.error.type == :response_status_not_found
  #     end
  #
  #     # Response status codes that are okay to leave uncovered (default: 401, 404, 500)
  #     test.ignored_unknown_status << 403
  #     test.ignore_unknown_response_status = true # or: ignore all unknown status codes
  #
  #     # Don't raise when a request doesn't match the API description at all
  #     test.ignore_unknown_requests = true
  #
  #     # Exclude parts of the API description from coverage tracking
  #     test.skip_response_coverage { |response_definition| response_definition.status == '5XX' }
  #     test.skip_coverage { |path, request_method| path == '/internal' && request_method == 'GET' }
  #
  #     # Require minimm of 95% coverage of the API description (default: 100)
  #     test.minimum_coverage = 95
  #
  #     # Report coverage always (default), only warn, or not at all: true / :warn / false
  #     test.report_coverage = :warn
  #   end
  #
  # See {OpenapiFirst::Test::Configuration} for the full list of options.
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

    def self.logger
      configuration.logger
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.registered?(oad)
      key = oad.key
      definitions.any? { |(_name, registered)| registered.key == key }
    end

    # Sets up OpenAPI test coverage and OAD registration.
    # @yield [OpenapiFirst::Test::Configuration] configuration A configuration to setup test integration
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
              "`OpenapiFirst::Test.setup { |test| test.register('myopenapi.yaml') }` "

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
        reporter: configuration.coverage_reporter,
        **configuration.coverage_reporter_options
      )
      return unless configuration.report_coverage == true

      coverage = Coverage.result.coverage
      minimum_coverage = configuration.minimum_coverage

      if coverage < minimum_coverage
        logger.error "API Coverage fails with exit 2, because not all described requests and responses have been tested (#{coverage.round(4)}% covered)." # rubocop:disable Layout/LineLength

        exit 2
      end

      return unless coverage - minimum_coverage >= 1.0

      logger.warn "API Coverage (#{coverage.round(4)}%) is higher than the configured minimum_coverage (#{minimum_coverage}%). You should probably increase minimum_coverage to #{coverage.round(4)}." # rubocop:disable Layout/LineLength
    end

    # Print the coverage report
    # @param reporter A reporter class to render the report.
    # @return [IO] An output where to puts the report.
    def self.report_coverage(reporter: Coverage::TerminalReporter, **)
      reporter.new(**).report(Coverage.result)
    end

    # Returns the Rack app wrapped with silent request, response validation
    # You can use this if you want to track coverage via Test::Coverage, but don't want to use
    # the middlewares or manual request, response validation.
    def self.app(app, spec: nil, api: :default, validate_request_before_handling: false)
      spec ||= self[api]
      App.new(app, api: spec, validate_request_before_handling:)
    end

    def self.install
      return if @installed

      OpenapiFirst.configure do |config|
        @after_request_validation = config.after_request_validation do |validated_request, oad|
          next unless registered?(oad)

          if configuration.raise_request_error?(validated_request)
            raise validated_request.error.exception if validated_request.unknown?

            check_unknown_query_parameters(validated_request)
          end

          Coverage.track_request(validated_request, oad)
        end

        @after_response_validation = config.after_response_validation do |validated_response, rack_request, oad|
          next unless registered?(oad)
          raise validated_response.error.exception if raise_response_error?(validated_response, rack_request)

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

      def many?(array) = array.length > 1

      def raise_response_error?(validated_response, rack_request)
        return false if validated_response.valid?

        configuration.raise_response_error?(validated_response, rack_request)
      end
    end
  end
end
