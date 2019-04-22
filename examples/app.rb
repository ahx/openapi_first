require 'openapi_first'
spec = OpenapiFirst.load('./openapi.yaml')

App = Rack::Builder.new do
  require 'openapi_first/query_parameter_validation'
  use OpenapiFirst::QueryParameterValidation, spec: spec

  # require 'openapi_first/request_body'
  # TODO: use OpenapiFirst::RequestBody, spec: spec

  # require 'openapi_first/request_body_validation'
  # TODO: use OpenapiFirst::RequestBodyValidation, spec: spec

  # require 'openapi_first/response_validation'
  # TODO: use OpenapiFirst::ResponseValidation, spec: spec

  run ->(_env) { Rack::Response.new('okay!') }
end
