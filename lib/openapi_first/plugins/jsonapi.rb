# frozen_string_literal: true

require_relative 'jsonapi/error_response'

module OpenapiFirst
  module Plugins
    module Jsonapi
      OpenapiFirst.register(:jsonapi, self)
    end
  end
end
