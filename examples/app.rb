require 'openapi_first'
require 'openapi_first/router'
require 'openapi_first/query_parameter_validation'
require 'openapi_first/request_body_validation'

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

  # use OpenapiFirst::ResponseValidation # TODO (only in development)
  # run OpenapiFirst::OperationResolver # TODO ?
  run (lambda do |_env|
    Rack::Response.new('Hello', 200)
  end)
end
