# frozen_string_literal: true

module OpenapiFirst
  # Configuration of hooks, plugins and options. {OpenapiFirst.configure} yields the global configuration.
  # A block passed to {OpenapiFirst.load} yields a child of it, which also runs the global hooks.
  #
  # @!method before_request_validation(&block)
  #   Adds a hook that runs before a request is validated. It runs only for requests that match an
  #   operation. Call {Failure.fail!} inside the block to mark the request as invalid.
  #   @yieldparam rack_request [Rack::Request]
  #   @yieldparam request_definition [RequestDefinition]
  #   @yieldparam definition [Definition]
  #   @return [Proc, Enumerable<Proc>] The block, or all hooks of this kind if no block is given
  #
  # @!method after_request_validation(&block)
  #   Adds a hook that runs after a request was validated, including unknown requests.
  #   Call {Failure.fail!} inside the block to mark the request as invalid.
  #   @yieldparam validated_request [ValidatedRequest]
  #   @yieldparam definition [Definition]
  #   @return [Proc, Enumerable<Proc>] The block, or all hooks of this kind if no block is given
  #
  # @!method after_response_validation(&block)
  #   Adds a hook that runs after a response was validated.
  #   It does not run for responses to requests that match no operation.
  #   @yieldparam validated_response [ValidatedResponse]
  #   @yieldparam rack_request [Rack::Request]
  #   @yieldparam definition [Definition]
  #   @return [Proc, Enumerable<Proc>] The block, or all hooks of this kind if no block is given
  #
  # @!method after_request_parameter_property_validation(&block)
  #   Adds a hook that runs for each request parameter after it was validated.
  #   @yieldparam data [Hash] The parsed parameters. Change a value in place to replace it.
  #   @yieldparam property [String] The parameter name
  #   @yieldparam property_schema [Hash] The JSON Schema of the parameter
  #   @yieldparam parent [nil]
  #   @return [Proc, Enumerable<Proc>] The block, or all hooks of this kind if no block is given
  #
  # @!method after_request_body_property_validation(&block)
  #   Adds a hook that runs for each property of an object in the request body after it was validated.
  #   @yieldparam data [Hash] The object that contains property. Change a value in place to replace it.
  #   @yieldparam property [String]
  #   @yieldparam property_schema [Hash] The JSON Schema of the property
  #   @yieldparam parent [Hash, nil]
  #   @return [Proc, Enumerable<Proc>] The block, or all hooks of this kind if no block is given
  #
  # @!method after_response_body_property_validation(&block)
  #   Adds a hook that runs for each property of an object in the response body after it was validated.
  #   @yieldparam data [Hash] The object that contains property. Change a value in place to replace it.
  #   @yieldparam property [String]
  #   @yieldparam property_schema [Hash] The JSON Schema of the property
  #   @yieldparam parent [Hash, nil]
  #   @return [Proc, Enumerable<Proc>] The block, or all hooks of this kind if no block is given
  class Configuration
    # The names of all hooks
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
      @regexp_resolver = nil
    end

    # Loads and registers an API description globally. See {OpenapiFirst.register}.
    # @param path_or_definition [String, Definition]
    # @param as [Symbol] The name to register it under
    # @return [Definition]
    def register(path_or_definition, as: :default, &)
      OpenapiFirst.register(path_or_definition, as:, &)
    end

    # @!attribute [r] hooks
    #   @return [Hash<Symbol, Set<Proc>>] The hooks added to this configuration, by hook name
    # @!attribute [r] request_validation_error_response
    #   @return [Class] The error response class the request validation middleware renders
    # @!attribute [r] regexp_resolver
    #   @return [String, Proc, nil] How JSON Schema `pattern` is evaluated. See {#regexp_resolver=}.
    attr_reader :hooks, :request_validation_error_response, :regexp_resolver

    # @!attribute [rw] path
    #   A Proc that receives the Rack::Request and returns the path to look up in the API description.
    #   Use this if your app is mounted under a path that the API description does not contain.
    #   @example
    #     config.path = ->(rack_request) { rack_request.path.delete_prefix('/api') }
    #   @return [Proc, nil]
    attr_accessor :path

    # Return a child configuration that still receives updates of global hooks.
    def child
      ChildConfiguration.new(parent: self)
    end

    # @api private
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

    # Loads a plugin and lets it configure this configuration.
    # @example
    #   config.plugin :x_public, field: 'x-visible'
    # @param name [Symbol] The plugin name, e.g. :x_public for {Plugins::XPublic}
    # @return [void]
    # @see Plugins
    def plugin(name, **)
      require_relative 'plugins'
      Plugins.load(name).configure(self, **)
    end

    # Sets how JSON Schema `pattern` is evaluated. It is passed to json_schemer as `regexp_resolver`.
    # OpenAPI requires ECMA-262 regular expressions, so 'ecma' is recommended.
    # @param resolver [String, Symbol, Proc] 'ruby' (default), 'ecma' or a Proc
    def regexp_resolver=(resolver)
      @regexp_resolver = resolver.is_a?(Symbol) ? resolver.to_s : resolver
    end

    # Sets the error response that the request validation middleware renders.
    # @param mod [Symbol, Class] A name registered via {OpenapiFirst.register_error_response}
    #   (:default, :jsonapi) or a class that includes {ErrorResponse}
    def request_validation_error_response=(mod)
      @request_validation_error_response = if mod.is_a?(Symbol)
                                             OpenapiFirst.find_error_response(mod)
                                           else
                                             mod
                                           end
    end
  end
end
