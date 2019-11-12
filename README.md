# OpenapiFirst

OpenapiFirst helps to implement HTTP APIs based on an [OpenApi](https://www.openapis.org/) API description. The idea is that you create an API description first, then add minimal code about your business logic (some call this "handler") and be done.

## TL;DR

Start with writing an OpenAPI file that describes the API, which you are about to write. Use a [validator](http://speccy.io/) to make sure the file is valid.
In the following examples, the OpenAPI file is named `openapi/openapi.yaml`.

Now implement your API:

```ruby
module Pets
  def self.find_pet(params, res)
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

- Validate the request and respond with 400 if the request does not match with your API description
- Map the request to a method call `Pets.find_pet` based on the `operationId` in the API description
- Set the response content type according to your spec (here with the default status code `200`)

Resolver functions (`find_pet`) are called with two arguments:

- `params` - Holds the parsed request body, filtered query params and path parameters
- `res` - Holds a Rack::Response that you can modify if needed
  If you want to access to plain Rack env you can call `params.env`.

You can also use the provided Rack middlewares to auto-implement only certain aspects of the request-response flow like query parameter or request body parameter validation based on your OpenAPI file. Read on to learn how.

### Handling only certain paths

You can filter the URIs that should be handled by pass ing `only` to `OpenapiFirst.load`:

```ruby
spec = OpenapiFirst.load './openapi/openapi.yaml', only: '/pets'.method(:==)
run OpenapiFirst.app(spec, namespace: Pets)
```

### Usage as Rack middleware

```ruby
# Just like the above, except the last line
# ...
run OpenapiFirst.middleware('./openapi/openapi.yaml', namespace: Pets)
```

When using the middleware, all requests that are not part of the API description will be passed to the next app.

## Try it out

See [example](examples)


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openapi_first'
```

OpenapiFirst uses [`multi_json`](https://rubygems.org/gems/multi_json).

## How it works

OpenapiFirst offers Rack middlewares to auto-implement different aspects for request handling:

- Request validation
- Mapping request to a function call

It starts by adding a router middleware:

```ruby
spec = OpenapiFirst.load('petstore.yaml')
use OpenapiFirst::Router, spec: spec
```

If the request is not valid, these middlewares return a 400 status code with a body that describes the error. If unkwon routes in your application exist, which are not specified in the API description, set `:allow_unknown_operation` to `true`.

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
## Request validation

```ruby
# Add the middleware:
use OpenapiFirst::RequestValidation
```

## Query parameter validation

By default OpenapiFirst does not allow additional query parameters and will respond with 400 if additional parameters are sent. You can allow additional parameters with `allow_allow_unknown_query_parameters: true`:

The middleware filteres all top-level query parameters and adds these to the Rack env: `env[OpenapiFirst::QUERY_PARAMS]`.
If you want to forbid _nested_ query parameters you will need to use [`additionalProperties: false`](https://json-schema.org/understanding-json-schema/reference/object.html#properties) in your query parameter JSON schema.

_OpenapiFirst always treats query parameters like [`style: deepObject`](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#style-values), **but** it just works with nested objects (`filter[foo][bar]=baz`) (see [this discussion](https://github.com/OAI/OpenAPI-Specification/issues/1706))._

### Request body validation

The middleware will return a `415` if the requests content type does not match or `400` if the request body is invalid.
This will add the parsed request body to `env[OpenapiFirst::REQUEST_BODY]`.

### Header, Cookie, Path parameter validation

tbd.

## Mapping the request to a method call

OpenapiFirst uses a `OperationResolver` middleware to map the HTTP request to a method call.

The resolver function is found via the [`operationId`](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#operation-object) attribute in your API description like this:

- `create_pet` will map to `MyApi.create_pet(params, response)`
- `some_things.create` will map to `MyApi::SomeThings.create(params, response)`
- `pets#create` will map to `MyApi::Pets::Create.new.call(params, response)` (like [Hanami::Router](https://github.com/hanami/router#controllers))

These handler methods are called with two arguments:

- `params` - Holds the parsed request body, filtered query params and path parameters
- `res` - Holds a Rack::Response that you can modify if needed

You can call `params.env` to access the Rack env (just like in [Hanami actions](https://guides.hanamirb.org/actions/parameters/))

There are two ways to set the response body:

- Calling `res.write "things"` (see [Rack::Response](https://www.rubydoc.info/github/rack/rack/Rack/Response))
- Returning a value from the function (see example above) (this will always converted to JSON)

### Adding the middleware

```ruby
# Define some methods
module MyApi
  def self.create_pet(params, res)
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

## Response validation

Response validation is useful to make sure your app responds as described in your API description. You usually do this in your tests using [rack-test](https://github.com/rack-test/rack-test).

```ruby
# In your test (rspec example):
require 'openapi_first'
spec = OpenapiFirst.load('petstore.yaml')
validator = OpenapiFirst::ResponseValidator.new(spec)

expect(validator.validate(last_request, last_response).errors).to be_empty
```

## Coverage

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

Currently out of scope.

## Alternatives

This gem is inspired by [committee](https://github.com/interagent/committee), which has much more features like response stubs or support for Hyper-Schema or OpenAPI 2.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Run benchmarks

```sh
cd benchmarks
bundle
bundle exec ruby benchmarks.rb
```

## Contributing

If you have a question or an idea or found a bug don't hesitate to [create an issue on GitHub](https://github.com/ahx/openapi_first/issues).

Pull requests are very welcome as well, of course. Feel free to create a "draft" pull request early on, even if your change is still work in progress. 🤗
