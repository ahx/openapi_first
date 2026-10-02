# frozen_string_literal: true

module OpenapiFirst
  # Unpacks parameters from a Hash of raw values, like path parameters, headers or cookies.
  # @visibility private
  class ParametersParser
    # @param parameters [Array<Parameter>]
    # @param check_encoding [Boolean] Raise Rack::Utils::InvalidParameterError if a value has an invalid encoding.
    def initialize(parameters, check_encoding:)
      @parameters = parameters
      @check_encoding = check_encoding
    end

    attr_reader :parameters

    # @param parameters_hash [Hash] The raw values, keyed by parameter name.
    def unpack(parameters_hash)
      parameters.each_with_object({}) do |parameter, result|
        next unless parameters_hash.key?(parameter.name)

        value = parameters_hash[parameter.name]
        check_encoding!(value) if @check_encoding
        result[parameter.name] = parameter.unpack_and_convert(value)
      end
    end

    private

    def check_encoding!(value)
      return if !value.is_a?(::String) || value.valid_encoding?

      raise Rack::Utils::InvalidParameterError, "invalid encoding (#{value.inspect})"
    end
  end
end
