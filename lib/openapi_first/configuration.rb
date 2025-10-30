# frozen_string_literal: true

module OpenapiFirst
  # Global configuration. Currently only used for the request validation middleware.
  class Configuration
    HOOKS = %i[
      after_request_validation
      after_response_validation
      after_request_parameter_property_validation
      after_request_body_property_validation
    ].freeze

    def initialize
      @request_validation_error_response = OpenapiFirst.find_error_response(:default)
      @request_validation_raise_error = false
      @response_validation_raise_error = true
      @hooks = HOOKS.to_h { [_1, Set.new] }
      @path = nil
    end

    def register(path_or_definition, as: :default)
      OpenapiFirst.register(path_or_definition, as:)
    end

    attr_reader :request_validation_error_response, :hooks
    attr_accessor :request_validation_raise_error, :response_validation_raise_error, :path

    def child
      ChildConfiguration.new(parent: self)
    end

    HOOKS.each do |hook|
      define_method(hook) do |&block|
        return hooks[hook] if block.nil?

        hooks[hook] << block
        block
      end
    end

    def request_validation_error_response=(mod)
      @request_validation_error_response = if mod.is_a?(Symbol)
                                             OpenapiFirst.find_error_response(mod)
                                           else
                                             mod
                                           end
    end
  end
end
