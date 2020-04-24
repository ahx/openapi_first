# frozen_string_literal: true

require 'openapi_first'

module Web
  module Things
    class Index
      def call(_params, _response)
        { hello: 'world' }
      end
    end
  end
end

oas_path = File.absolute_path('./openapi.yaml', __dir__)
App = OpenapiFirst.app(oas_path, namespace: Web)
