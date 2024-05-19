# frozen_string_literal: true

require_relative 'validators/headers'
require_relative 'validators/response_body'

module OpenapiFirst
  module ResponseValidation
    class Validator
      VALIDATORS = [
        Validators::Headers,
        Validators::ResponseBody
      ].freeze

      def initialize(response_definition)
        @validators = VALIDATORS.filter_map do |klass|
          klass.for(response_definition)
        end
      end

      def call(parsed_response)
        catch FAILURE do
          @validators.each { |v| v.call(parsed_response) }
          nil
        end
      end
    end
  end
end
