# frozen_string_literal: true

require_relative 'validation_error'

module OpenapiFirst
  module Schema
    # A hash of Schemas
    # @api private
    class Hash
      # @param schemas Hash of schemas
      # @param required Array of required keys
      # @param defaults Hash of default values
      def initialize(schemas, required: nil, defaults: {}, **options)
        @schemas = schemas
        @defaults = defaults
        @after_property_validation = options.delete(:after_property_validation)
        schema = { 'type' => 'object' }
        schema['required'] = required if required
        @root_schema = JSONSchemer.schema(schema, **options)
      end

      def validate(root_value)
        validation = @root_schema.validate(root_value)
        validations = @schemas.reduce(validation) do |enum, (key, schema)|
          root_value[key] = @defaults[key] if @defaults.key?(key) && !root_value.key?(key)
          next enum unless root_value.key?(key)

          value = root_value[key]
          key_validation = schema.validate(value)
          @after_property_validation&.each do |hook|
            hook.call(root_value, key, schema.value, nil)
          end
          enum.chain(key_validation.map do |err|
            err.merge('data_pointer' => "/#{key}")
          end)
        end
        ValidationResult.new(validations)
      end
    end
  end
end
