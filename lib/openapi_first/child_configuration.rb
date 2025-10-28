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

    HOOKS.each do |hook|
      define_method(hook) do |&block|
        return hooks[hook].chain(parent.hooks[hook]) if block.nil?

        hooks[hook] << block
        block
      end
    end
  end
end
