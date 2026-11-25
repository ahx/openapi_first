# frozen_string_literal: true

module OpenapiFirst
  class NotRegisteredError < Error; end
  class AlreadyRegisteredError < Error; end

  # @api private
  module Registry
    # @return [Hash<Symbol, Definition>] The registered API descriptions by name
    def definitions
      @definitions ||= {}
    end

    def register(path_or_definition, as: :default, &)
      if definitions.key?(as) && as == :default
        raise(
          AlreadyRegisteredError,
          "#{definitions[as].inspect} is already registered " \
          "as ':default' so you cannot register #{path_or_definition.inspect} without " \
          'giving it a custom name. Please call register with a custom key like: ' \
          "#{name}.register(#{path_or_definition.inspect}, as: :my_other_api)"
        )
      end
      definition = OpenapiFirst.load(path_or_definition, &)
      definitions[as] = definition
      definition
    end

    def [](api)
      return api if api.is_a?(Definition)

      definitions.fetch(api) do
        option = api == :default ? '' : ", as: #{api.inspect}"
        raise(NotRegisteredError,
              "API description '#{api.inspect}' not found." \
              "Please call #{name}.register('myopenapi.yaml'#{option}) " \
              'once before running your app.')
      end
    end
  end
end
