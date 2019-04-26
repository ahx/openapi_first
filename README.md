# OpenapiFirst

OpenapiFirst offers tools to help test and implement Rack apps based on an [OpenApi](https://www.openapis.org/) API description.

## TL;DR

This is all in flux.
It is usable, but the syntax might have changed next time you come here.

```ruby
require 'rack'
require 'openapi_first'
require 'openapi_first/router'
require 'openapi_first/query_parameter_validation'

SPEC = OpenapiFirst.load('./openapi/openapi.yaml')

App = Rack::Builder.new do
  use OpenapiFirst::Router, spec: SPEC
  use OpenapiFirst::QueryParameterValidation

  run (lambda do |_env|
    Rack::Response.new('Hello', 200)
  end)
end
```

See [`examples/`](examples/) for more.

## Start

Start with writing an OpenAPI file that describes the API, which you are about to write. Use a [validator](http://speccy.io/) to make sure the file is valid.

We recommend saving the file as `openapi/openapi.yaml`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openapi_first'
```

OpenapiFirst uses [`multi_json`](https://rubygems.org/gems/multi_json).

## Testing

OpenapiFirst offers tools to help testing your app.

### Response validation

Response validation is to make sure your app responds as described in your OpenAPI spec. You usually do this in your tests using [rack-test](https://github.com/rack-test/rack-test).

```ruby
# In your test:
require 'openapi_first/response_validator'
spec = OpenapiFirst.load('petstore.yaml')
validator = OpenapiFirst::ResponseValidator.new(spec)
validator.validate(last_request, last_response).errors? # => true or false
```

### Coverage

(This is a bit experimental. Please try it out and give feedback.)

`OpenapiFirst::Coverage` helps you make sure, that you have called all endpoints of your OAS file when running tests via `rack-test`.

```ruby
# In your test (rspec example):
require 'openapi_first/coverage'

describe MyApp do
  include Rack::Test::Methods

  before(:all) do
    spec = OpenapiFirst.load('petstore.yaml')
    @app_wrapper = OpenapiFirst::TestCoverage.new(MyApp, spec)
  end

  after(:all) do
    message = "The following paths have not been called yet: #{@app_wrapper.to_be_called}"
    expect(@app_wrapper.to_be_called).to be_empty
  end

  # Overwrite `#app` to make rack-test call the wrapped app
  def app
    @app_wrapper
  end

  it 'does things' do
    get '/i/my/stuff'
    # …
  end
end
```

## Implementing

OpenapiFirst offers Rack middlewares to auto-implement different aspects of request validation:

- Query parameter validation
- Request body validation

To make it all work you have to add the router middleware first:

```ruby
spec = OpenapiFirst.load('petstore.yaml')

require 'openapi_first/router'
use OpenapiFirst::Router, spec: myspec
```

If the request is not valid, these middlewares return a 400 status code with a body that describes the error.

The error responses conform with [JSON:API](https://jsonapi.org).

Here's an example response body for a missing query parameter "search":

```json
http-status: 400
content-type: "application/vnd.api+json"

{
  "errors": [
    {
      "title": "is missing",
      "source": {
        "parameter": "search"
      }
    }
  ]
}
```

### Query parameter validation

```ruby
# Add the middleware (after the Router):
require 'openapi_first/query_parameter_validation'
use OpenapiFirst::QueryParameterValidation
```

By default OpenapiFirst does not allow additional query parameters and will respond with 400 if additional parameters are sent. You can allow additional parameters with `additional_properties: true`:

```ruby
use OpenapiFirst::QueryParameterValidation,
    allow_additional_parameters: true
```

The middleware filteres all top-level query parameters and adds these to the Rack env: `env[OpenapiFirst::QUERY_PARAMS]`.
If you want to forbid nested query parameters you will need to use `additionalProperties: false` in your query parameter json schema.

OpenapiFirst does not support parameters set to `explode: false` and treats nested query parameters (`filter[foo]=bar`) like [`style: deepObject`](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#style-values).

### TODO: Header, Cookie, Path parameter validation

tbd.

### TODO: Request Body validation

Request body validation is build of these middlewares:

1. `RequestBody` - Parses the request body via [`Rack::Parser`](https://rubygems.org/gems/rack-parser)
2. `RequestBodyValidation` - Validates the parsed request body

```ruby
# Add these middlewares:
require 'openapi_first/request_body_parser'
use OpenapiFirst::RequestBodyParser

require 'openapi_first/request_body_validation'
use OpenapiFirst::RequestBodyValidation
```

OpenAPI request (and response) body validation is based on [JSON Schema](http://json-schema.org/).

## TODO: Mocking

## Alternatives

This gem is inspired by [committee](https://github.com/interagent/committee), which has much more features like response stubs or support for Hyper-Schema or OpenAPI 2.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ivx/openapi_first.
