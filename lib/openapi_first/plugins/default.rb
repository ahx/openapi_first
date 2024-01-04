# frozen_string_literal: true

require_relative 'default/error_response'

module OpenapiFirst
  module Plugins
    module Default
      OpenapiFirst.register(:default, self)
    end
  end
end
