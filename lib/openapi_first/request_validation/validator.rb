# frozen_string_literal: true

require_relative '../failure'
require_relative 'validators/parameters'
require_relative 'validators/request_body'

module OpenapiFirst
  module RequestValidation
    # Validates a Request against an Operation.
    class Validator
      VALIDATORS = [
        Validators::Parameters,
        Validators::RequestBody
      ].freeze

      def initialize(request_definition, openapi_version:, hooks: {})
        @validators = VALIDATORS.filter_map do |klass|
          klass.for(request_definition, hooks:, openapi_version:)
        end
      end

      def call(parsed_request)
        catch FAILURE do
          @validators.each { |v| v.call(parsed_request) }
          nil
        end
      end
    end
  end
end
