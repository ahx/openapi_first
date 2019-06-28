# OpenapiFirst

OpenapiFirst offers tools to help test and implement Rack apps based on an [OpenApi](https://www.openapis.org/) API description.

## TL;DR

This is all in flux.
It is usable, but the syntax might have changed next time you come here.

```ruby
module Pets
  def self.find_pet(params, _res) # "find_pet" is an operationId from your OpenApi file
    {
      id: params['id'],
      name: 'Oscar'
    }
  end
end

# In config.ru:
require 'openapi_first'
run OpenapiFirst.app('./openapi/openapi.yaml', namespace: Pets)
```

The above will:

- Validate the request and respond with 400 if the request does not match against your spec
- Map the request (for example `GET /pet/1`) to the method call `Pets.find_pet`
- Set the content type according to your spec (here with the default status code `200`)

## Start

Start with writing an OpenAPI file that describes the API, which you are about to write. Use a [validator](http://speccy.io/) to make sure the file is valid.

We recommend saving the file as `openapi/openapi.yaml`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openapi_first'
```

OpenapiFirst uses [`multi_json`](https://rubygems.org/gems/multi_json).

## Implementing

OpenapiFirst offers Rack middlewares to auto-implement different aspects of request validation:

- Query parameter validation
- Request body validation
- Mapping request to a function call

It starts with a router middleware:

```ruby
spec = OpenapiFirst.load('petstore.yaml')
use OpenapiFirst::Router, spec: spec
```

If the request is not valid, these middlewares return a 400 status code with a body that describes the error. If unkwon routes in your application exist, which are not specified in the openapi spec file, set `:allow_unknown_operation` to `true`.

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

### Request Body validation

```ruby
# Add the middleware:
use OpenapiFirst::RequestBodyValidation
```

This will return a `415` if the requests content type does not match or `400` if the request body is invalid.
This will add the parsed request body to `env[OpenapiFirst::REQUEST_BODY]`.

OpenAPI request (and response) body validation is based on [JSON Schema](http://json-schema.org/).

### Mapping request to a function call

OpenapiFirst has a `OperationResolver` middleware to map the HTTP request to a function (method) call

```ruby
# Define some methods
module MyApi
  def create_pet(params, res)
    res.status = 201
    {
      id: '1',
      name: params['name']
    }
  end
end

# Add the middleware:
use OpenapiFirst::OperationResolver, namespace: MyApi
# If the operation was not found in the OAS file, the next app will be called

# OR use it as a Rack app via `run`:
run OpenapiFirst::OperationResolver, namespace: Pets
# If the operation was not found, this will return 404

# Now make a request like
# POST /pets, { name: 'Oscar' }
```

The resolver function is found via the [`operationId`](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#operation-object) attribute in your API description. If your operationId has dots like `Pets.find`, the resolver above would call `MyApi::Pets.find(params, req)`.

These resolver functions are called with two arguments:

- `params` - Holds the parsed request body, filtered query params and path parameters
- `res` - Holds a Rack::Response that you can modify if needed

You can call `params.env` to access the Rack env (just like in [Hanami actions](https://guides.hanamirb.org/actions/parameters/))

There are two ways to set the response body:

- Calling `res.write "things"` (see [Rack::Response](https://www.rubydoc.info/github/rack/rack/Rack/Response))
- Returning a value from the function (see example above) (this will always converted to JSON)

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

TODO: Add RSpec matcher (via extra rubygem)

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
    @app_wrapper = OpenapiFirst::Coverage.new(MyApp, spec)
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

## Mocking

Currently out of scope. Use https://github.com/JustinFeng/fakeit or something else.

## Alternatives

This gem is inspired by [committee](https://github.com/interagent/committee), which has much more features like response stubs or support for Hyper-Schema or OpenAPI 2.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ivx/openapi_first.
