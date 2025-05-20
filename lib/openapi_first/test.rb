# frozen_string_literal: true

module OpenapiFirst
  # Test integration
  module Test
    autoload :Coverage, 'openapi_first/test/coverage'
    autoload :Methods, 'openapi_first/test/methods'

    def self.minitest?(base)
      base.include?(::Minitest::Assertions)
    rescue NameError
      false
    end

    # Helper class to setup tests
    class Setup
      def initialize
        @minimum_coverage = 0
        @coverage_formatter = Coverage::TerminalFormatter
        @coverage_formatter_options = {}
        @skip_response_coverage = nil
        yield self
      end

      def register(oad, as: :default)
        Test.register(oad, as:)
      end

      attr_accessor :minimum_coverage, :coverage_formatter_options, :coverage_formatter

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

    # Sets up OpenAPI test coverage and OAD registration.
    # @yieldparam [OpenapiFirst::Test::Setup] setup A setup for configuration
    def self.setup(&)
      unless block_given?
        raise ArgumentError, "Please provide a block to #{self.class}.setup to register you API descriptions"
      end

      Coverage.install
      setup = Setup.new(&)
      Coverage.start(skip_response: setup.skip_response_coverage)

      if definitions.empty?
        raise NotRegisteredError,
              'No API descriptions have been registered. ' \
              'Please register your API description via ' \
              "OpenapiFirst::Test.setup { |test| test.register('myopenapi.yaml') }"
      end

      @setup ||= at_exit do
        setup.handle_exit
      end
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
    end
  end
end
