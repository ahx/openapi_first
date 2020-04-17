# frozen_string_literal: true

require 'rack'

module OpenapiFirst
  class OperationResolver
    NOT_FOUND = Rack::Response.new('', 404).finish.freeze
    DEFAULT_APP = ->(_env) { NOT_FOUND }

    def initialize(app = DEFAULT_APP, options) # rubocop:disable Style/OptionalArguments
      @app = app
      @namespace = options.fetch(:namespace)
    end

    def call(env) # rubocop:disable Metrics/AbcSize
      operation = env[OpenapiFirst::OPERATION]
      return @app.call(env) unless operation

      operation_id = operation.operation_id
      res = Rack::Response.new
      params = build_params(env)
      handler = find_handler(operation_id)
      result = handler.call(params, res)
      res.write MultiJson.dump(result) if result && res.body.empty?
      res[Rack::CONTENT_TYPE] ||= find_content_type(operation, res.status)
      res.finish
    end

    def find_handler(operation_id)
      if operation_id.include?('.')
        module_name, method_name = operation_id.split('.')
        return @namespace.const_get(module_name.camelize).method(method_name)
      end

      if operation_id.include?('#')
        module_name, class_name = operation_id.split('#')
        return @namespace.const_get(module_name.camelize)
                         .const_get(class_name.camelize).new
      end
      @namespace.method(operation_id)
    end

    private

    def find_content_type(operation, status)
      content = operation
                .response_by_code(status.to_s, use_default: true)
                .content
      content.keys[0] if content
    end

    def build_params(env)
      sources = [
        env[PATH_PARAMS],
        env[QUERY_PARAMS],
        env[REQUEST_BODY]
      ].tap(&:compact!)
      Params.new(env).merge!(*sources)
    end
  end

  class Params < Hash
    attr_reader :env

    def initialize(env)
      @env = env
      super()
    end
  end
end
