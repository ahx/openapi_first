# frozen_string_literal: true

module OpenapiFirst
  # Global configuration. Currently only used for the request validation middleware.
  class Configuration
    HOOKS = %i[
      before_request_validation
      after_request_validation
      after_response_validation
      after_request_parameter_property_validation
      after_request_body_property_validation
      after_response_body_property_validation
    ].freeze

    def initialize
      @request_validation_error_response = OpenapiFirst.find_error_response(:default)
      @hooks = HOOKS.to_h { [_1, Set.new] }
      @path = nil
    end

    def register(path_or_definition, as: :default)
      OpenapiFirst.register(path_or_definition, as:)
    end

    attr_reader :hooks, :request_validation_error_response
    attr_accessor :path

    # Return a child configuration that still receives updates of global hooks.
    def child
      ChildConfiguration.new(parent: self)
    end

    # @visibility private
    def clone
      raise NoMethodError, 'OpenapiFirst::Configuration#clone was removed. You want to call #child instead'
    end

    HOOKS.each do |hook|
      define_method(hook) do |&block|
        return hooks[hook] if block.nil?

        hooks[hook] << block
        block
      end
    end

    def plugin(name, **)
      require_relative 'plugins'
      Plugins.load(name).configure(self, **)
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
