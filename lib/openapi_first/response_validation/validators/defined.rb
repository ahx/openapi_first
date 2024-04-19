# frozen_string_literal: true

module OpenapiFirst
  module ResponseValidation
    module Validators
      class Defined
        def self.for(_response_definition)
          self
        end

        def self.call(response)
          return if response.known?

          unless response.known_status?
            message = "Response status '#{response.status}' is not defined"
            Failure.fail!(:response_not_found, message:)
          end

          if response.content_type.nil? || response.content_type.empty?
            message = 'Content-Type must not be empty'
            Failure.fail!(:invalid_response_header, message:)
          end

          message = "Content-Type '#{content_type}' is not defined"
          Failure.fail!(:invalid_response_header, message:)
        end
      end
    end
  end
end
