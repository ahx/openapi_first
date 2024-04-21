# frozen_string_literal: true

module OpenapiFirst
  module RequestValidation
    module Validators
      class Path
        def self.for(_request_definition, hooks: {})
          self
        end

        def self.call(request)
          Failure.fail!(:not_found) unless request.path_item
        end
      end
    end
  end
end
