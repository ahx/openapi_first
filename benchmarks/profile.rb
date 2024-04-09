require 'vernier'
require 'rack'
require 'openapi_first'

definition = OpenapiFirst.load('./apps/openapi.yaml')
Vernier.trace(out: 'profiles/request_validation_profile.json') do
  1000.times do
    env = Rack::MockRequest.env_for('/hello?filter[id]=1,2')
    definition.validate_request(Rack::Request.new(env), raise_error: true)
  end
end
