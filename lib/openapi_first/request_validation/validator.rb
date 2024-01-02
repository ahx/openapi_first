# frozen_string_literal: true

module OpenapiFirst
  class NotFoundError < StandardError; end

  module RequestValidation
    class Validator
      def initialize(operation)
        @operation = operation
      end

      def validate(runtime_request)
        catch(FAIL) do
          validate_defined(runtime_request)
          validate_parameters!(runtime_request)
          validate_request_body!(runtime_request)
          nil
        end
      end

      private

      attr_reader :operation, :raw_path_params

      def validate_defined(request)
        return if request.known?

        message = "Request '#{request.original.request_method} #{request.original.path}' is not defined"
        status =  request.known_path? ? 415 : 404
        RequestValidation.fail!(:not_found, status:, message:)
      end

      def validate_parameters!(request)
        validate_query_params!(request)
        validate_path_params!(request)
        validate_cookie_params!(request)
        validate_header_params!(request)
      end

      def validate_path_params!(request)
        parameters = operation.path_parameters
        return unless parameters

        validation_result = parameters.schema.validate(request.path_params)
        RequestValidation.fail!(:path, validation_result:) if validation_result.error?
      end

      def validate_query_params!(request)
        parameters = operation.query_parameters
        return unless parameters

        validation_result = parameters.schema.validate(request.query)
        RequestValidation.fail!(:query, validation_result:) if validation_result.error?
      end

      def validate_cookie_params!(request)
        parameters = operation.cookie_parameters
        return unless parameters

        validation_result = parameters.schema.validate(request.cookies)
        RequestValidation.fail!(:cookie, validation_result:) if validation_result.error?
      end

      def validate_header_params!(request)
        parameters = operation.header_parameters
        return unless parameters

        validation_result = parameters.schema.validate(request.headers)
        RequestValidation.fail!(:header, validation_result:) if validation_result.error?
      end

      def validate_request_body!(request)
        RequestBodyValidator.new(operation).validate!(request)
      end
    end
  end
end