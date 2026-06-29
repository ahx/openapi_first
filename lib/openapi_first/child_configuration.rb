# frozen_string_literal: true

module OpenapiFirst
  # A subclass to configuration that points to its parent
  class ChildConfiguration < Configuration
    def initialize(parent:)
      super()
      @parent = parent
      @request_validation_error_response = parent.request_validation_error_response
      @request_validation_raise_error = parent.request_validation_raise_error
      @response_validation_raise_error = parent.response_validation_raise_error
      @path = parent.path
    end

    private attr_reader :parent

    # The schema backend is global, so it cannot be set per definition (it would silently affect everything).
    def schema_backend=(_value)
      raise ArgumentError,
            'The schema backend is global and cannot be set per definition. ' \
            'Configure it via `OpenapiFirst.plugin :jsonschema_rs` or ' \
            '`OpenapiFirst.configure { |config| config.schema_backend = ... }`.'
    end

    HOOKS.each do |hook|
      define_method(hook) do |&block|
        return hooks[hook].chain(parent.hooks[hook]) if block.nil?

        hooks[hook] << block
        block
      end
    end
  end
end
