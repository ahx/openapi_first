# frozen_string_literal: true

require_relative 'openapi_first/json'
require_relative 'openapi_first/file_loader'
require_relative 'openapi_first/errors'
require_relative 'openapi_first/configuration'
require_relative 'openapi_first/definition'
require_relative 'openapi_first/version'
require_relative 'openapi_first/middlewares/response_validation'
require_relative 'openapi_first/middlewares/request_validation'

# OpenapiFirst is a toolchain to build HTTP APIS based on OpenAPI API descriptions.
module OpenapiFirst
  autoload :Test, 'openapi_first/test'

  # Key in rack to find instance of Request
  REQUEST = 'openapi.request'

  # Key in rack env that stores the alternative path used for schema matching
  RACK_KEY_PATH_TO_MATCH = 'openapi.path_to_match'

  FAILURE = :openapi_first_validation_failure

  # @return [Configuration]
  def self.configuration
    @configuration ||= Configuration.new
  end

  # @return [Configuration]
  # @yield [Configuration]
  def self.configure
    yield configuration
  end

  ERROR_RESPONSES = {} # rubocop:disable Style/MutableConstant
  private_constant :ERROR_RESPONSES

  # Retrieve the path used for schema matching.
  #
  # @param [Rack::Request] rack_request
  def self.get_path_to_match(rack_request)
    rack_request.env[RACK_KEY_PATH_TO_MATCH] || rack_request.path
  end

  # Register an error response class
  # @param name [Symbol]
  # @param klass [Class] A class that includes / implements OpenapiFirst::ErrorResponse
  def self.register_error_response(name, klass)
    ERROR_RESPONSES[name.to_sym] = klass
  end

  # @param name [Symbol]
  # @return [Class] The error response class
  def self.find_error_response(name)
    ERROR_RESPONSES.fetch(name) do
      raise "Unknown error response: #{name}. " /
            'Register your error response class via `OpenapiFirst.register_error_response(name, klass)`. ' /
            "Registered error responses are: #{ERROR_RESPONSES.keys.join(', ')}."
    end
  end

  # Load and dereference an OpenAPI spec file
  # @return [Definition]
  def self.load(filepath, only: nil, &)
    raise FileNotFoundError, "File not found: #{filepath}" unless File.exist?(filepath)

    contents = FileLoader.load(filepath)
    parse(contents, only:, filepath:, &)
  end

  # Parse a dereferenced Hash
  # @return [Definition]
  def self.parse(contents, only: nil, filepath: nil, &)
    # TODO: This needs to work with unresolved contents as well
    contents['paths'].filter!(&->(key, _) { only.call(key) }) if only
    Definition.new(contents, filepath, &)
  end
end

require_relative 'openapi_first/error_response'
require_relative 'openapi_first/error_responses/default'
require_relative 'openapi_first/error_responses/jsonapi'
