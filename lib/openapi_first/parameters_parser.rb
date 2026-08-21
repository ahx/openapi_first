# frozen_string_literal: true

module OpenapiFirst
  # Unpacks parameters from a Hash of raw values, like path parameters, headers or cookies.
  # @visibility private
  class ParametersParser
    # @param parameters [Array<Parameter>]
    def initialize(parameters)
      @parameters = parameters
    end

    attr_reader :parameters

    # @param values [Hash] The raw values, keyed by parameter name.
    def unpack(values)
      parameters.each_with_object({}) do |parameter, result|
        next unless values.key?(parameter.name)

        result[parameter.name] = parameter.unpack_and_convert(values[parameter.name])
      end
    end
  end
end
