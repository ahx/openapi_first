require 'rack/contrib/not_found'
require 'openapi_first'
require 'openapi_first/router'
require 'openapi_first/query_parameter_validation'
require 'openapi_first/request_body_validation'
require 'openapi_first/operation_resolver'

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
  use OpenapiFirst::OperationResolver, namespace: Example
  run Rack::NotFound
end
