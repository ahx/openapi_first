# frozen_string_literal: true

require 'openapi_first'

module Example
  def self.get_metadata(_params, _res)
    { hello: 'world' }
  end
end

App = Rack::Builder.new do
  SPEC = OpenapiFirst.load(File.absolute_path('./openapi.yaml', __dir__))

  use OpenapiFirst::Router, spec: SPEC

  # use OpenapiFirst::RequestValidation # TODO
  # or:
  use OpenapiFirst::QueryParameterValidation
  # use OpenapiFirst::HeaderParameterValidation # TODO ?
  # use OpenapiFirst::PathParameterValidation # TODO ?
  # use OpenapiFirst::CookieParameterValidation # TODO ?
  use OpenapiFirst::RequestBodyValidation

  # use OpenapiFirst::ResponseValidation # TODO (only in development, test)
  run OpenapiFirst::OperationResolver.new(namespace: Example)
end
