# frozen_string_literal: true

module OpenapiFirst
  # A subclass to configuration that points to its parent
  class ChildConfiguration < Configuration
    def initialize(parent:)
      super()
      @parent = parent
      @request_validation_error_response = nil
      @path = parent.path
      @regexp_resolver = parent.regexp_resolver
    end

    private attr_reader :parent

    def request_validation_error_response
      @request_validation_error_response || parent.request_validation_error_response
    end

    HOOKS.each do |hook|
      define_method(hook) do |&block|
        return hooks[hook].chain(parent.public_send(hook)) if block.nil?

        hooks[hook] << block
        block
      end
    end
  end
end
