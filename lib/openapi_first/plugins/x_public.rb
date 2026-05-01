# frozen_string_literal: true

module OpenapiFirst
  module Plugins
    # Enforces that only operations explicitly marked as public are accessible.
    # Throws a :not_found failure for any matched operation that lacks the configured field.
    #
    # Options:
    #   field: [String] The OpenAPI extension field to check. Default: 'x-public'.
    #   if:    [Proc]   Optional condition proc. Receives the Rack::Request and must
    #                   return truthy for the check to apply. Use this to restrict the
    #                   plugin to certain hosts or path prefixes.
    #
    # Example:
    #   OpenapiFirst.plugin :x_public
    #   OpenapiFirst.plugin :x_public, field: 'x-visible'
    #   OpenapiFirst.plugin :x_public, if: ->(req) { req.host == 'api.example.com' }
    module XPublic
      def self.configure(config, field: 'x-public', **opts)
        condition = opts[:if]
        config.before_request_validation do |request, request_definition|
          next if condition && !condition.call(request)

          Failure.fail!(:not_found) unless request_definition.operation[field]
        end
      end
    end
  end
end
