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

      def initialize(operation, hooks: {})
        @validators = VALIDATORS.filter_map do |klass|
          klass.for(operation, hooks:)
        end
      end

      def call(parsed_request)
        catch Failure::FAILURE do
          @validators.each { |v| v.call(parsed_request) }
          nil
        end
      end
    end
  end
end
