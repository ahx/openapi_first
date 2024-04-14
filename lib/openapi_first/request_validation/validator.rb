# frozen_string_literal: true

require_relative '../failure'
require_relative 'validators/cookies'
require_relative 'validators/headers'
require_relative 'validators/path'
require_relative 'validators/path_parameters'
require_relative 'validators/query'
require_relative 'validators/request_body'
require_relative 'validators/request_method'

module OpenapiFirst
  module RequestValidation
    # Validates a Request against an Operation.
    class Validator
      VALIDATORS = [
        Validators::Path,
        Validators::RequestMethod,
        Validators::PathParameters,
        Validators::Query,
        Validators::Headers,
        Validators::Cookies,
        Validators::RequestBody
      ].freeze

      def initialize(request_definition)
        @validators = VALIDATORS.filter_map do |klass|
          klass.for(request_definition)
        end
      end

      def call(request)
        catch Failure::FAILURE do
          @validators.each { |v| v.call(request) }
          nil
        end
      end
    end
  end
end
