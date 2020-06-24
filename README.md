# OpenapiFirst

[![Join the chat at https://gitter.im/openapi_first/community](https://badges.gitter.im/openapi_first/community.svg)](https://gitter.im/openapi_first/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

OpenapiFirst helps to implement HTTP APIs based on an [OpenApi](https://www.openapis.org/) API description. The idea is that you create an API description first, then add code that returns data and implements your business logic and be done.

Start with writing an OpenAPI file that describes the API, which you are about to implement. Use a [validator](https://github.com/stoplightio/spectral/) to make sure the file is valid.

You can use OpenapiFirst via its [Rack middlewares](#rack-middlewares) or in [standalone mode](#standalone-usage).

## Alternatives

This gem is inspired by [committee](https://github.com/interagent/committee) (Ruby) and [connexion](https://github.com/zalando/connexion) (Python).

Here's a [comparison between committee and openapi_first](https://gist.github.com/ahx/1538c31f0652f459861713b5259e366a).

## Rack middlewares
OpenapiFirst consists of these Rack middlewares:

- [`OpenapiFirst::Router`](#OpenapiFirst::Router) – Finds the OpenAPI operation for the current request or returns 404 if no operation was found. This can be customized.
- [`OpenapiFirst::RequestValidation`](#OpenapiFirst::RequestValidation) – Validates the request against the API description and returns 400 if the request is invalid.
- [`OpenapiFirst::Responder`](#OpenapiFirst::Responder) calls the [handler](#handlers) found for the operation.
- [`OpenapiFirst::ResponseValidation`](#OpenapiFirst::ResponseValidation) Validates the response and raises an exception if the response body is invalid.

## OpenapiFirst::Router
You always have to add this middleware first in order to make the other middlewares work.

```ruby
use OpenapiFirst::Router, spec: OpenapiFirst.load('./openapi/openapi.yaml')
```

This middleware adds `env[OpenapiFirst::OPERATION]` which holds an Operation object that responds to `operation_id` and `path`.

Options and their defaults:

| Name | Possible values | Description | Default
|:---|---|---|---|
|`spec:`| | The spec loaded via `OpenapiFirst.load` ||
| `raise_error:` |`false`, `true` | If set to true the middleware raises `OpenapiFirst::NotFoundError` when a path or method was not found in the API description. This is useful during testing to spot an incomplete API description. | `false` (don't raise an exception)

## OpenapiFirst::RequestValidation

This middleware returns a 400 status code with a body that describes the error if the request is not valid.

```ruby
use OpenapiFirst::RequestValidation
```


Options and their defaults:

| Name | Possible values | Description | Default
|:---|---|---|---|
| `raise_error:` |`false`, `true` | If set to true the middleware raises `OpenapiFirst::RequestInvalidError` instead of returning 4xx. | `false` (don't raise an exception)

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

This middleware adds `env[OpenapiFirst::INBOX]` which holds the (filtered) path and query parameters and the parsed request body.

### Parameter validation

The middleware filteres all top-level query parameters and paths parameters and tries to convert numeric values. Meaning, if you have an `:something_id` path with `type: integer`, it will try convert the value to an integer.
Note that is currently does not convert date, date-time or time formats and that conversion is currently done only for path and query parameters, but not for the request body. It just works with a parameter with `name: filter[age]`.

If you want to forbid _nested_ query parameters you will need to use [`additionalProperties: false`](https://json-schema.org/understanding-json-schema/reference/object.html#properties) in your query parameter JSON schema.

_OpenapiFirst always treats query parameters like [`style: deepObject`](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#style-values), **but** it just works with nested objects (`filter[foo][bar]=baz`) (see [this discussion](https://github.com/OAI/OpenAPI-Specification/issues/1706))._

### Request body validation

The middleware will return a status `415` if the requests content type does not match or `400` if the request body is invalid.
This will also add the parsed request body to `env[OpenapiFirst::REQUEST_BODY]`.

### Header, Cookie, Path parameter validation

tbd.

## OpenapiFirst::Responder

This Rack endpoint maps the HTTP request to a method call based on the [operationId](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#operation-object) in your API description and calls it. Responder also adds a content-type to the response.

Currently there are no customization options for this part. Please [share your ideas](#contributing) on how to best meet your needs and preferred style.

```ruby
run OpenapiFirst::Responder, spec: OpenapiFirst.load('./openapi/openapi.yaml')
```

| Name | Description
|:---|---|
|`spec:`| The spec loaded via `OpenapiFirst.load` |
| `namespace:` | A class or module where to find the handler method. |

It works like this:

- An operationId "create_pet" or "createPet" or "create pet" calls `MyApi.create_pet(params, response)`
- "some_things.create" calls: `MyApi::SomeThings.create(params, response)`
- "pets#create" calls: `MyApi::Pets::Create.new.call(params, response)` If `MyApi::Pets::Create.new` accepts an argument, it will pass the rack `env`.

### Handlers

These handler methods are called with two arguments:

- `params` - Holds the parsed request body, filtered query params and path parameters (same as `env[OpenapiFirst::INBOX]`)
- `res` - Holds a Rack::Response that you can modify if needed

You can call `params.env` to access the Rack env (just like in [Hanami actions](https://guides.hanamirb.org/actions/parameters/))

There are two ways to set the response body:

- Calling `res.write "things"` (see [Rack::Response](https://www.rubydoc.info/github/rack/rack/Rack/Response))
- Returning a value which will get converted to JSON

## OpenapiFirst::ResponseValidation
This middleware is especially useful when testing. It *always* raises an error if the response is not valid.

```ruby
use OpenapiFirst::ResponseValidation if ENV['RACK_ENV'] == 'test'
```

## Standalone usage
Instead of composing these middlewares yourself you can use `OpenapiFirst.app`.

```ruby
module Pets
  def self.find_pet(params, res)
    {
      id: params[:id],
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

### Options and their defaults:

| Name | Possible values | Description | Default
|:---|---|---|---|
| `namespace:` || A class or module where to find the handler method.
| `raise_error:` | `true`, `false` | If set to true the middleware raises an exception (subclass of `OpenapiFirst::Error` when a request is not specified or the request is not valid. This is useful during testing. | `false`

Handler functions (`find_pet`) are called with two arguments:

- `params` - Holds the parsed request body, filtered query params and path parameters
- `res` - Holds a Rack::Response that you can modify if needed
  If you want to access to plain Rack env you can call `params.env`.

## If your API description does not contain all endpoints

```ruby
run OpenapiFirst.middleware('./openapi/openapi.yaml', namespace: Pets)
```

Here all requests that are not part of the API description will be passed to the next app.

## Try it out

See [examples](examples).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openapi_first'
```

OpenapiFirst uses [`multi_json`](https://rubygems.org/gems/multi_json).

## Manual response validation

Instead of using the ResponseValidation middleware you can validate the response in your test manually via [rack-test](https://github.com/rack-test/rack-test) and ResponseValidator.

```ruby
# In your test (rspec example):
require 'openapi_first'
spec = OpenapiFirst.load('petstore.yaml')
validator = OpenapiFirst::ResponseValidator.new(spec)

# This will raise an exception if it found an error
validator.validate(last_request, last_response)
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
