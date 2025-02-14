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
      def register(*)
        Test.register(*)
      end
    end

    def self.setup
      unless block_given?
        raise ArgumentError, "Please provide a block to #{self.class}.setup to register you API descriptions"
      end

      Coverage.start
      setup = Setup.new
      yield setup
      return unless definitions.empty?

      raise NotRegisteredError,
            'No API descriptions have been registered. ' \
            'Please register your API description via ' \
            "OpenapiFirst::Test.setup { |test| test.register('myopenapi.yaml') }"
    end

    # Print the coverage report
    # @param formatter A formatter to define the report.
    # @output [IO] An output where to puts the report.
    def self.report_coverage(formatter: Coverage::TerminalFormatter)
      coverage_result = Coverage.result
      puts formatter.new.format(coverage_result)
      puts "The overal API validation coverage of this run is: #{coverage_result.coverage}%"
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

      def register(path, as: :default)
        if definitions.key?(:default)
          raise(
            AlreadyRegisteredError,
            "#{definitions[as].filepath.inspect} is already registered " \
            "as ':default' so you cannot register #{path.inspect} without " \
            'giving it a custom name. Please call register with a custom key like: ' \
            "OpenapiFirst::Test.register(#{path.inspect}, as: :my_other_api)"
          )
        end

        definitions[as] = OpenapiFirst.load(path)
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
