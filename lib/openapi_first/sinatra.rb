# frozen_string_literal: true

# :nocov:
begin
  require 'sinatra/base'
rescue LoadError
  raise LoadError, 'openapi_first/sinatra needs the `sinatra` gem. Add `gem "sinatra"` to your Gemfile.'
end
# :nocov:

require 'did_you_mean'
require 'openapi_first'

module OpenapiFirst
  # Sinatra extension to define routes by referencing operations in an OpenAPI description via operationId.
  #
  #   require 'openapi_first/sinatra'
  #
  # In a classic (top-level) app the extension is registered automatically, so the +openapi+
  # and +operation+ keywords are available right away:
  #
  #   require 'sinatra'
  #   require 'openapi_first/sinatra'
  #
  #   openapi 'openapi.yaml'
  #   operation :create_customer do
  #     json create_customer(parsed_params)
  #   end
  #
  # In a modular app register it explicitly, like any other Sinatra extension:
  #
  #   require 'sinatra/base'
  #   require 'openapi_first/sinatra'
  #
  #   class PetsApi < Sinatra::Base
  #     register OpenapiFirst::Sinatra
  #     openapi 'openapi.yaml'
  #
  #     operation :index_pets do |params|
  #       json index_pets(params[:filter])
  #     end
  #
  #     operation :create_pet do
  #       json create_pet(parsed_body[:data])
  #     end
  #   end
  #
  # Each +operation+ route validates its request against the OpenAPI description before the block
  # runs, so contract violations return 400/415 and the block is not reached. Validation reuses
  # Sinatra's own routing (the operation's path template is known when the route is defined), so
  # openapi_first does not run its own router - there is no request-validation middleware.
  #
  # Because routing is left to Sinatra, requests to paths without an +operation+ block fall through
  # to Sinatra's normal handling (a 404 by default), and you can add plain Sinatra routes
  # (health checks, assets, ...) alongside +operation+ blocks.
  # This relaxes the strict approach of openapi_first's request validation middleware
  # where all unknown routes that are not described in the OAD return 404. Take care to avoid API drift
  #
  # NOTE: Requests are matched by Sinatra's router (Mustermann), but validated against the OpenAPI path
  # template the route was defined from, using the path parameters Sinatra extracted. The two
  # matchers can diverge at the edges (trailing slashes, dots inside a path segment,
  # encoded characters, ...) - a request Sinatra matches is not re-checked against openapi_first's own
  # path matching. Avoid path shapes where the two routers disagree.
  module Sinatra
    PATH_PARAMETER = /\{[^}]+\}/
    private_constant :PATH_PARAMETER

    # The configuration lives in Sinatra settings (rather than plain instance variables) so a
    # subclass of a configured app inherits the loaded description and its operation index.
    def self.registered(app)
      app.helpers(Helpers)
      # Declared up front so the reader methods exist (returning nil) before #openapi runs,
      # which keeps the "call `openapi` first" guard in #operation working.
      app.set :openapi_definition, nil
      app.set :openapi_operations_index, nil
      app.set :openapi_error_response, nil
    end

    # Loads an OpenAPI description for this app. Call this once per app; the loaded description is
    # then available via {#openapi_definition}. Each {#operation} route validates its request
    # against the description before the block runs.
    # @param spec [String, Symbol, OpenapiFirst::Definition] A file path, a key registered via
    #   OpenapiFirst.register, or a Definition instance.
    # @return [OpenapiFirst::Definition]
    # @raise [OpenapiFirst::Error] if {#openapi} has already been called for this app.
    def openapi(spec)
      raise ::OpenapiFirst::Error, '`openapi` can only be called once per app.' if openapi_definition

      definition = ::OpenapiFirst.load(spec)
      set :openapi_definition, definition
      set :openapi_operations_index, build_operation_index(definition)
      set :openapi_error_response, ::OpenapiFirst.configuration.request_validation_error_response
      definition
    end

    # Defines a route for the operation with the given +operationId+. The HTTP method and path
    # are taken from the OpenAPI description; the block is the Sinatra route handler.
    #
    # If the block declares an argument, it receives {Helpers#parsed_params}:
    #
    #   operation(:show_pet) { |params| json find_pet(params[:id]) }
    #
    # A block without arguments runs as a normal Sinatra route (use {Helpers#parsed_params} inside).
    # A block that takes a splat or optional argument (arity < 0) is also passed {Helpers#parsed_params}.
    #
    # Symbols are the idiomatic form (+operation :create_customer+). Use a String for operationIds
    # that are not valid Ruby symbols, e.g. +operation 'pets.list'+.
    # @param operation_id [String, Symbol] An operationId present in the API description.
    # @raise [OpenapiFirst::Error] if {#openapi} has not been called yet.
    # @raise [ArgumentError] if the operationId is not defined in the API description.
    def operation(operation_id, &block)
      unless openapi_operations_index
        raise ::OpenapiFirst::Error, 'Call `openapi` with your API description before defining operations.'
      end

      request_method, path = openapi_operations_index.fetch(operation_id.to_s) do
        raise ArgumentError, unknown_operation_message(operation_id.to_s)
      end
      public_send(request_method.downcase, sinatra_pattern(path), &operation_handler(path, block))
    end

    private

    def unknown_operation_message(operation_id)
      defined_ids = openapi_operations_index.keys
      message = "Operation #{operation_id.inspect} is not defined in #{openapi_definition.key}."
      suggestions = ::DidYouMean::SpellChecker.new(dictionary: defined_ids).correct(operation_id)
      message << if suggestions.any?
                   " Did you mean #{suggestions.map(&:inspect).join(' or ')}?"
                 else
                   " Defined operationIds are: #{defined_ids.join(', ')}."
                 end
    end

    def operation_handler(path_template, block)
      param_names = path_template.scan(PATH_PARAMETER).map! { |placeholder| placeholder[1..-2] }
      proc do |*captures|
        path_params = param_names.zip(captures).to_h
        validated = settings.openapi_definition.validate_request(request, path_template:, path_params:)
        env[::OpenapiFirst::REQUEST] = validated
        if (failure = validated.error) && (error_response = settings.openapi_error_response)
          halt(*error_response.new(failure:).render)
        end

        block.arity.zero? ? instance_exec(&block) : instance_exec(parsed_params, &block)
      end
    end

    def sinatra_pattern(path)
      path.gsub(PATH_PARAMETER) { |placeholder| ":#{placeholder[1..-2].gsub(/[^A-Za-z0-9_]/, '_')}" }
    end

    def build_operation_index(definition)
      definition.routes.each_with_object({}) do |route, index|
        route.requests.each do |request|
          operation_id = request.operation_id
          next unless operation_id

          entry = [route.request_method, route.path]
          existing = index[operation_id]
          if existing && existing != entry
            raise ::OpenapiFirst::Error,
                  "operationId #{operation_id.inspect} is used for #{existing.join(' ')} and " \
                  "#{entry.join(' ')} in #{definition.key}. operationIds must be unique."
          end

          index[operation_id] = entry
        end
      end
    end

    # Helpers available inside route blocks.
    module Helpers
      # The merged path and query parameters parsed and coerced per the OpenAPI description. See also
      # OpenapiFirst::ValidatedRequest#parsed_query, OpenapiFirst::ValidatedRequest#parsed_path_parameters).
      #
      # Sinatra's own +params+ is left untouched and still returns the raw, unparsed values. For
      # parts that can have colliding names, read them explicitly via {#openapi_request}
      # (e.g. +openapi_request.parsed_headers+).
      #
      # @return [Sinatra::IndifferentHash]
      def parsed_params
        ::Sinatra::IndifferentHash[openapi_request.parsed_query.merge(openapi_request.parsed_path_parameters)]
      end

      # The parsed request body
      # @return [Sinatra::IndifferentHash, Object, nil]
      def parsed_body
        body = openapi_request.parsed_body
        body.is_a?(Hash) ? ::Sinatra::IndifferentHash[body] : body
      end

      # Generates a URL for the operation with the given +operationId+, filling in any path
      # parameters from +path_params+. Delegates to Sinatra's own +url+ helper so reverse-proxy
      # and script-name handling is preserved.
      #
      #   href = operation_url(:show_pet, petId: pet.id)   # => "http://example.com/pets/42"
      #
      # @param operation_id [String, Symbol] An operationId present in the API description.
      # @param path_params [Hash] Path-parameter values keyed by name (String or Symbol).
      # @return [String] Absolute URL for the operation.
      # @raise [ArgumentError] if the operationId is unknown or a required path parameter is missing.
      def operation_url(operation_id, path_params = {})
        url(settings.openapi_definition.path_for(path_params, operation_id:))
      end

      # @return [OpenapiFirst::ValidatedRequest] The validated request for the current request.
      def openapi_request
        env[::OpenapiFirst::REQUEST]
      end
    end
  end
end

# Make the +openapi+/+operation+ keywords available to classic (top-level) apps, so that
# requiring this single file is enough. Modular apps still `register OpenapiFirst::Sinatra`.
Sinatra.register(OpenapiFirst::Sinatra)
