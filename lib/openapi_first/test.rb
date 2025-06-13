# frozen_string_literal: true

require_relative 'test/configuration'

module OpenapiFirst
  # Test integration
  module Test
    autoload :Coverage, 'openapi_first/test/coverage'
    autoload :Methods, 'openapi_first/test/methods'

    class CoverageError < Error; end

    def self.minitest?(base)
      base.include?(::Minitest::Assertions)
    rescue NameError
      false
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    # Sets up OpenAPI test coverage and OAD registration.
    # @yieldparam [OpenapiFirst::Test::Configuration] configuration A configuration to setup test integration
    def self.setup
      unless block_given?
        raise ArgumentError, "Please provide a block to #{self.class}.confgure to register you API descriptions"
      end

      install
      yield configuration
      configuration.registry.each do |name, oad|
        register(oad, as: name)
      end
      Coverage.start(skip_response: configuration.skip_response_coverage)

      if definitions.empty?
        raise NotRegisteredError,
              'No API descriptions have been registered. ' \
              'Please register your API description via ' \
              "OpenapiFirst::Test.setup { |test| test.register('myopenapi.yaml') }"
      end

      @exit_handler = method(:handle_exit)

      @setup ||= at_exit do
        # :nocov:
        @exit_handler&.call
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

      raise OpenapiFirst::Test::CoverageError, 'Not all described requests and responses have been tested.'
    end

    # Print the coverage report
    # @param formatter A formatter to define the report.
    # @output [IO] An output where to puts the report.
    def self.report_coverage(formatter: Coverage::TerminalFormatter, **)
      coverage_result = Coverage.result
      puts formatter.new(**).format(coverage_result)
    end

    # Returns the Rack app wrapped with silent request, response validation
    # You can use this if you want to track coverage via Test::Coverage, but don't want to use
    # the middlewares or manual request, response validation.
    def self.app(app, spec: nil, api: :default)
      spec ||= self[api]
      Rack::Builder.app do
        use OpenapiFirst::Middlewares::ResponseValidation, spec:, raise_error: false
        use OpenapiFirst::Middlewares::RequestValidation, spec:, raise_error: false, error_response: false
        run app
      end
    end

    def self.install
      return if @installed

      OpenapiFirst.configure do |config|
        @after_request_validation = config.after_request_validation do |validated_request, oad|
          after_request_validation(validated_request, oad)
        end
        @after_response_validation = config.after_response_validation do |validated_response, rack_request, oad|
          after_response_validation(validated_response, rack_request, oad)
        end
      end
      @installed = true
    end

    def self.uninstall
      configuration = OpenapiFirst.configuration
      configuration.hooks[:after_request_validation].delete(@after_request_validation)
      configuration.hooks[:after_response_validation].delete(@after_response_validation)
      definitions.clear
      @configuration = nil
      @installed = nil
      @exit_handler = nil
    end

    class NotRegisteredError < StandardError; end
    class AlreadyRegisteredError < StandardError; end

    @definitions = {}

    class << self
      attr_reader :definitions

      # Register an OpenAPI definition for testing
      # @param path_or_definition [String, Definition] Path to the OpenAPI file or a Definition object
      # @param as [Symbol] Name to register the API definition as
      def register(path_or_definition, as: :default)
        if definitions.key?(as) && as == :default
          raise(
            AlreadyRegisteredError,
            "#{definitions[as].filepath.inspect} is already registered " \
            "as ':default' so you cannot register #{path_or_definition.inspect} without " \
            'giving it a custom name. Please call register with a custom key like: ' \
            "OpenapiFirst::Test.register(#{path_or_definition.inspect}, as: :my_other_api)"
          )
        end

        definition = OpenapiFirst.load(path_or_definition)
        definitions[as] = definition
        definition
      end

      def [](api)
        definitions.fetch(api) do
          option = api == :default ? '' : ", as: #{api.inspect}"
          raise(NotRegisteredError,
                "API description '#{api.inspect}' not found." \
                "Please call OpenapiFirst::Test.register('myopenapi.yaml'#{option}) " \
                'once before running tests.')
        end
      end

      private

      def after_request_validation(validated_request, oad)
        Coverage.track_request(validated_request, oad)
      end

      def after_response_validation(validated_response, request, oad)
        raise validated_response.error.exception if configuration.response_raise_error && validated_response.invalid?

        Coverage.track_response(validated_response, request, oad)
      end
    end
  end
end
