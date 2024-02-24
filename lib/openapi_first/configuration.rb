# frozen_string_literal: true

module OpenapiFirst
  # Global configuration. Currently only used for the request validation middleware.
  class Configuration
    def initialize
      @request_validation_error_response = OpenapiFirst.find_plugin(:default)::ErrorResponse
      @request_validation_raise_error = false
      @hooks = {}
    end

    attr_reader :request_validation_error_response, :hooks
    attr_accessor :request_validation_raise_error

    def clone
      copy = super
      copy.instance_variable_set(:@hooks, @hooks&.transform_values(&:clone))
      copy
    end

    %i[
      after_request_validation
      after_response_validation
      after_request_parameter_property_validation
      after_request_body_property_validation
    ].each do |hook|
      define_method(hook) do |&block|
        @hooks[hook] ||= []
        hooks[hook] << block
      end
    end

    def request_validation_error_response=(mod)
      @request_validation_error_response = if mod.is_a?(Symbol)
                                             OpenapiFirst.find_plugin(:default)::ErrorResponse
                                           else
                                             mod
                                           end
    end
  end
end
