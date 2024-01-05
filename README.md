# OpenapiFirst

[![Join the chat at https://gitter.im/openapi_first/community](https://badges.gitter.im/openapi_first/community.svg)](https://gitter.im/openapi_first/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

OpenapiFirst helps to implement HTTP APIs based on an [OpenAPI](https://www.openapis.org/) API description. It supports OpenAPI 3.0 and 3.1.

It provides these Rack middlewares:

- [`OpenapiFirst::Middlewares::RequestValidation`](#request-validation) – Validates the request against the API description and returns 4xx if the request is invalid.
- [`OpenapiFirst::Middlewares::ResponseValidation`](#response-validation) Validates the response and raises an exception if the response body is invalid.

Using request and response validation together ensures that your implementation follows exactly the API description. This enables you to use the API description as a single source of truth for your API, reason about details and use various tooling.

## Middlewares

`OpenapiFirst` offers one Rack middleware for request validation and one for response validation. Both add a _request_ object to the current Rack env at `env[OpenapiFirst::REQUEST]` (or `env['openapi.request']`), which is in an instance of `OpenapiFirst::RuntimeRequest`. This gives you access to the converted query and path parameters exaclty as described in your API instead of relying on Rack alone parse the request. This only includes the parameters that are defined in the API description. It supports every [`style` and `explode` value as described](https://spec.openapis.org/oas/latest.html#style-examples) in the OpenAPI 3.0 and 3.1 specs.

### Request validation

This middleware returns a 400 status code with a body that describes the error if the request is not valid.

```ruby
use OpenapiFirst::RequestValidation, spec: 'openapi.yaml'
```

#### Options and defaults

| Name              | Possible values                                                 | Description                                                                                        | Default                            |
| :---------------- | --------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- | ---------------------------------- |
| `spec:`           |                                                                 | The path to the spec file or spec loaded via `OpenapiFirst.load`                                   |
| `raise_error:`    | `false`, `true`                                                 | If set to true the middleware raises `OpenapiFirst::RequestInvalidError` instead of returning 4xx. | `false` (don't raise an exception) |
| `error_response:` | `:default`, `:json_api`, Your implementation of `ErrorResponse` | :default                                                                                           |

Here's an example response body about an invalid request body. See also [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457).

```json
http-status: 400
content-type: "application/json"

{
  "title": "Bad Request Body",
  "status": 400,
  "errors": [
    {
      "message": "value at `/data/name` is not a string",
      "pointer": "/data/name",
      "code": "string"
    },
    {
      "message": "number at `/data/numberOfLegs` is less than: 2",
      "pointer": "/data/numberOfLegs",
      "code": "minimum"
    },
    {
      "message": "object at `/data` is missing required properties: mandatory",
      "pointer": "/data",
      "code": "required"
    }
  ]
}
```

### readOnly / writeOnly properties

Request validation fails if request includes a property with `readOnly: true`.

Response validation fails if response body includes a property with `writeOnly: true`.

## Response validation

This middleware is especially useful when testing. It _always_ raises an error if the response is not valid.

```ruby
use OpenapiFirst::ResponseValidation, spec: 'openapi.yaml' if ENV['RACK_ENV'] == 'test'
```

### Options

| Name    | Possible values | Description                                                      | Default |
| :------ | --------------- | ---------------------------------------------------------------- | ------- |
| `spec:` |                 | The path to the spec file or spec loaded via `OpenapiFirst.load` |

## Global configuration

You can configure default options globally:

```ruby
OpenapiFirst.configure do |config|
  # Specify which plugin is used to render error responses returned by the request validation middleware (defaults to :default)
  config.request_validation_error_response = :json_api
  # Configure if the response validation middleware should raise an exception (defaults to false)
  config.request_validation_raise_error = true
end
```

## Plugins

OpenapiFirst offers a simple plugin system. See lib/openapi_first/plugins for details. (tbd.)

## Manual validation

Instead of using the middlewares you can validate the request and response manually.

```ruby
require 'openapi_first'
definition = OpenapiFirst.load('petstore.yaml')

## Request validation
definition.request(Rack::Request.new(env)).validate # returns nil if request is valid, OpenapiFirst::RequestValidation::Failure if not
# or
definition.request(Rack::Request.new(env)).validate! # returns nil if request is valid, raises an exception if not

## Response validation
response = app.call(env)
definition.request(Rack::Request.new(env)).response(response).validate! # returns nil if request is valid, raises an exception if not
```

## Handling only certain paths

You can filter the URIs that should be handled by passing `only` to `OpenapiFirst.load`:

```ruby
spec = OpenapiFirst.load('./openapi/openapi.yaml', only: { |path| path.starts_with? '/pets' })
use OpenapiFirst::RequestValidation, spec: spec
```

## Alternatives

This gem is inspired by [committee](https://github.com/interagent/committee) (Ruby) and [connexion](https://github.com/zalando/connexion) (Python).

Here's a [comparison between committee and openapi_first](https://gist.github.com/ahx/1538c31f0652f459861713b5259e366a).

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
validator = OpenapiFirst::ResponseValidator.new('petstore.yaml')

# This will raise an exception if it found an error
validator.validate(last_request, last_response)
```

## Handling only certain paths

You can filter the URIs that should be handled by passing `only` to `OpenapiFirst.load`:

```ruby
spec = OpenapiFirst.load('./openapi/openapi.yaml', only: ->(path) { path.starts_with? '/pets' })
use OpenapiFirst::RequestValidation, spec: spec
```

## Development

Run `bin/setup` to install dependencies.

See `bundle exec rake` to run the linter and the tests.

Run `bundle exec rspec` to run the tests only.

## Benchmarks

[Results](https://gist.github.com/ahx/e6ffced58bd2e8d5baffb2f4d2c1f823)

### Run benchmarks

```sh
cd benchmarks
bundle
bundle exec ruby benchmarks.rb
```

## Contributing

If you have a question or an idea or found a bug don't hesitate to [create an issue on GitHub](https://github.com/ahx/openapi_first/issues) or [reach out via chat](https://gitter.im/openapi_first/community).

Pull requests are very welcome as well, of course. Feel free to create a "draft" pull request early on, even if your change is still work in progress. 🤗
