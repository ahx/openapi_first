# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    module Validators
      class RequestMethod
        def self.for(_request_definition, hooks: {})
          self
        end

        def self.call(request)
          Failure.fail!(:method_not_allowed) unless request.operation
        end
      end
    end
  end
end
