# OpenapiFirst

OpenapiFirst offers tools to help test and implement Rack apps based on an [OpenApi](https://www.openapis.org/) API description.

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

OpenapiFirst offers tools to help implementing your app.

### Request Validation

OpenapiFirst offers Rack middlewares to auto-implement different aspects of request validation:

- Request parameter validation
- Request body validation

If the request is not valid, these middlewares return a 400 status code with a body that describes the error.

The error responses conform with [JSON:API](https://jsonapi.org).

Here's and example response body for a missing query parameter "search":

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

### Request parameter validation

```ruby
# Add the middleware:
require 'openapi_first/request_parameter_validation'
use OpenapiFirst::RequestParameterValidation, spec: myspec
```

### TODO: Request Body validation

```ruby
# Add the middleware:
require 'openapi_first/request_body_validation'
use OpenapiFirst::RequestBodyValidation, spec: myspec
```

This middleware will parse the request body with [`Rack::Parser`](https://rubygems.org/gems/rack-parser]).

## TODO: Mocking

## Alternatives

This gem is inspired by [committee](https://github.com/interagent/committee), which has much more features like response stubs or support for Hyper-Schema or OpenAPI 2.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ivx/openapi_first.
