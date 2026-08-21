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

    # @param parameters_hash [Hash] The raw values, keyed by parameter name.
    def unpack(parameters_hash)
      parameters.each_with_object({}) do |parameter, result|
        next unless parameters_hash.key?(parameter.name)

        result[parameter.name] = parameter.unpack_and_convert(parameters_hash[parameter.name])
      end
    end
  end
end
