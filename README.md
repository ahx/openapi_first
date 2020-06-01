# OpenapiFirst

OpenapiFirst helps to implement HTTP APIs based on an [OpenApi](https://www.openapis.org/) API description. The idea is that you create an API description first, then add code that returns data and implements your business logic and be done.

Start with writing an OpenAPI file that describes the API, which you are about to write. Use a [validator](https://github.com/stoplightio/spectral/) to make sure the file is valid.

## Rack middlewares
OpenapiFirst consists of these Rack middlewares:

- `OpenapiFirst::Router` – Finds the operation for the current request or returns 404 if no operation was found. This can be customized.
- `OpenapiFirst::RequestValidation` – Validates the request against the API description and returns 400 if the request is invalid.
- `OpenapiFirst::OperationResolver` calls the [handler](#handlers) found for the operation.
- `OpenapiFirst::ResponseValidation` (Work in progress) validates the response and raises an exception if the response body is invalid.

## OpenapiFirst::Router
Options and their defaults:

| Name | Possible values | Description | Default
|:---|---|---|---|
| `not_found:` |`nil`, `:continue`, `Proc`| Specifies what to do if path was not found in the API description. `nil` (default) returns a 404 response. `:continue` does nothing an calls the next app. `Proc` (or something that responds to `call`) to customize the response. | `nil` (return 404)
| `raise:` |`false`, `true` | If set to true the middleware raises `OpenapiFirst::NotFoundError` when a path or method was not found in the API description. This is useful during testing to spot an incomplete API description. | `false` (don't raise an exception)

## OpenapiFirst::ResponseValidation

```ruby
use OpenapiFirst::ResponseValidation if ENV['RACK_ENV'] == 'test'
```

## Usage within your Rack webframework
If you just want to use the request validation part without any handlers you can use the rack middlewares standalone:

```ruby
use OpenapiFirst::Router, spec: OpenapiFirst.load('./openapi/openapi.yaml')
use OpenapiFirst::RequestValidation
```

### Rack env variables
These variables will available in your rack env:

- `env[OpenapiFirst::OPERATION]` - Holds an Operation object that responsed about `operation_id` and `path`. This is useful for introspection.
- `env[OpenapiFirst::INBOX]`. Holds the (filtered) path and query parameters and the parsed request body.


## Standalone usage
You can implement your API in conveniently with just OpenapiFirst.

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

The above will use the mentioned Rack middlewares to:

- Validate the request and respond with 400 if the request does not match with your API description
- Map the request to a method call `Pets.find_pet` based on the `operationId` in the API description
- Set the response content type according to your spec (here with the default status code `200`)

Handler functions (`find_pet`) are called with two arguments:

- `params` - Holds the parsed request body, filtered query params and path parameters
- `res` - Holds a Rack::Response that you can modify if needed
  If you want to access to plain Rack env you can call `params.env`.

### Handlers

OpenapiFirst maps the HTTP request to a method call based on the [operationId](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#operation-object) in your API description and calls it via the `OperationResolver` middleware.

It works like this:

- "create_pet" or "createPet" or "create pet" calls `MyApi.create_pet(params, response)`
- "some_things.create" calls: `MyApi::SomeThings.create(params, response)`
- "pets#create" calls: `MyApi::Pets::Create.new.call(params, response)` If `MyApi::Pets::Create.new` accepts an argument, it will pass the rack `env`.

These handler methods are called with two arguments:

- `params` - Holds the parsed request body, filtered query params and path parameters
- `res` - Holds a Rack::Response that you can modify if needed

You can call `params.env` to access the Rack env (just like in [Hanami actions](https://guides.hanamirb.org/actions/parameters/))

There are two ways to set the response body:

- Calling `res.write "things"` (see [Rack::Response](https://www.rubydoc.info/github/rack/rack/Rack/Response))
- Returning a value from the function (see example above) (this will always converted to JSON)

### If your API description does not contain all endpoints

```ruby
run OpenapiFirst.middleware('./openapi/openapi.yaml', namespace: Pets)
```

Here all requests that are not part of the API description will be passed to the next app.

### Try it out

See [examples](examples).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openapi_first'
```

OpenapiFirst uses [`multi_json`](https://rubygems.org/gems/multi_json).

## Request validation

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

### Parameter validation

The middleware filteres all top-level query parameters and paths parameters and tries to convert numeric values. Meaning, if you have an `:something_id` path with `type: integer`, it will try convert the value to an integer.
Note that is currently does not convert date, date-time or time formats and that conversion is currently on done for path and query parameters, but not for request bodies.

If you want to forbid _nested_ query parameters you will need to use [`additionalProperties: false`](https://json-schema.org/understanding-json-schema/reference/object.html#properties) in your query parameter JSON schema.

_OpenapiFirst always treats query parameters like [`style: deepObject`](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#style-values), **but** it just works with nested objects (`filter[foo][bar]=baz`) (see [this discussion](https://github.com/OAI/OpenAPI-Specification/issues/1706))._

### Request body validation

The middleware will return a `415` if the requests content type does not match or `400` if the request body is invalid.
This will add the parsed request body to `env[OpenapiFirst::REQUEST_BODY]`.

### Header, Cookie, Path parameter validation

tbd.

## Response validation

Response validation is useful to make sure your app responds as described in your API description. You usually do this in your tests using [rack-test](https://github.com/rack-test/rack-test).

```ruby
# In your test (rspec example):
require 'openapi_first'
spec = OpenapiFirst.load('petstore.yaml')
validator = OpenapiFirst::ResponseValidator.new(spec)

expect(validator.validate(last_request, last_response).errors).to be_empty
```

## Handling only certain paths

You can filter the URIs that should be handled by passing `only` to `OpenapiFirst.load`:

```ruby
spec = OpenapiFirst.load './openapi/openapi.yaml', only: '/pets'.method(:==)
run OpenapiFirst.app(spec, namespace: Pets)
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

Out of scope. Use [Prism](https://github.com/stoplightio/prism) or [fakeit](https://github.com/JustinFeng/fakeit).

## Alternatives

This gem is inspired by [committee](https://github.com/interagent/committee) (Ruby) and [connexion](https://github.com/zalando/connexion) (Python).

## Development

Run `bin/setup` to install dependencies.

Run `bundle exec rspec` to run the tests.

See `bundle exec rake -T` for rubygems related tasks.

### Run benchmarks

```sh
cd benchmarks
bundle
bundle exec ruby benchmarks.rb
```

## Contributing

If you have a question or an idea or found a bug don't hesitate to [create an issue on GitHub](https://github.com/ahx/openapi_first/issues) or [reach out via chat](https://gitter.im/openapi_first/community).

Pull requests are very welcome as well, of course. Feel free to create a "draft" pull request early on, even if your change is still work in progress. 🤗
