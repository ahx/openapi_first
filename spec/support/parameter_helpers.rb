# frozen_string_literal: true

module ParameterHelpers
  def build_parameter(definition)
    _media_type, media_type_object = definition['content']&.first
    OpenapiFirst::Parameter.new(definition, schema: (media_type_object || definition)['schema'])
  end

  def build_parameters(definitions)
    definitions.map { build_parameter(_1) }
  end
end
