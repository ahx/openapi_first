# openapi_first

OpenapiFirst helps to implement HTTP APIs based on an [OpenAPI](https://www.openapis.org/) API description. It supports OpenAPI 3.0 and 3.1. It offers request and response validation and it ensures that your implementation follows exactly the API description.

## Contents

<!-- TOC -->

- [Manual use](#manual-use)
- [Rack Middlewares](#rack-middlewares)
- [Configuration](#configuration)
- [Development](#development)

<!-- /TOC -->

## Manual use

Load the API description:

```ruby
require 'openapi_first'

definition = OpenapiFirst.load('petstore.yaml')
```

Validate request / response:

```ruby

# Find the request
rack_request = Rack::Request.new(env) # GET /pets/42
request = definition.request(rack_request)

# Inspect the request and access parsed parameters
request.known? # Is the request defined in the API description?
request.content_type
request.body # alias: parsed_body
request.path_parameters # => { "pet_id" => 42 }
request.query_parameters # alias: query
request.params # Merged path and query parameters
request.headers
request.cookies
request.request_method # => "get"
request.path # => "/pets/42"
request.path_definition # => "/pets/{pet_id}"

# Validate the request
request.validate # Returns OpenapiFirst:::Failure if validation fails
request.validate! # Raises OpenapiFirst::RequestInvalidError or OpenapiFirst::NotFoundError if validation fails

# Find the response
rack_response = Rack::Response[*app.call(env)]
response = request.response(rack_response) # or definition.response(rack_request, rack_response)

# Inspect the response
response.known? # Is the response defined in the API description?
response.status # => 200
response.content_type
response.body
request.headers # parsed response headers

# Validate response
response.validate # Returns OpenapiFirst::Failure if validation fails
response.validate! # Raises OpenapiFirst::ResponseInvalidError or OpenapiFirst::ResponseNotFoundError if validation fails
```

OpenapiFirst uses [`multi_json`](https://rubygems.org/gems/multi_json).

## Rack Middlewares

All middlewares add a _request_ object to the current Rack env at `env[OpenapiFirst::REQUEST]`), which is in an instance of `OpenapiFirst::RuntimeRequest` that responds to `.params`, `.parsed_body` etc.

This gives you access to the converted request parameters and body exaclty as described in your API description instead of relying on Rack alone to parse the request. This only includes query parameters that are defined in the API description. It supports every [`style` and `explode` value as described](https://spec.openapis.org/oas/latest.html#style-examples) in the OpenAPI 3.0 and 3.1 specs.

### Request validation

The request validation middleware returns a 4xx if the request is invalid or not defined in the API description.

```ruby
use OpenapiFirst::Middlewares::RequestValidation, spec: 'openapi.yaml'
```

#### Options

| Name              | Possible values                                                           | Description                                                                                                                         |
| :---------------- | ------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `spec:`           |                                                                           | The path to the spec file or spec loaded via `OpenapiFirst.load`                                                                    |
| `raise_error:`    | `false` (default), `true`                                                 | If set to true the middleware raises `OpenapiFirst::RequestInvalidError` or `OpenapiFirst::NotFoundError` instead of returning 4xx. |
| `error_response:` | `:default` (default), `:json_api`, Your implementation of `ErrorResponse` | :default                                                                                                                            |

Here's an example response body about an invalid request body. See also [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457).

```json
http-status: 400
content-type: "application/problem+json"

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

#### readOnly / writeOnly properties

Request validation fails if request includes a property with `readOnly: true`.

Response validation fails if response body includes a property with `writeOnly: true`.

### Response validation

This middleware is especially useful when testing. It _always_ raises an error if the response is not valid.

```ruby
use OpenapiFirst::Middlewares::ResponseValidation, spec: 'openapi.yaml' if ENV['RACK_ENV'] == 'test'
```

#### Options

| Name    | Possible values | Description                                                      |
| :------ | --------------- | ---------------------------------------------------------------- |
| `spec:` |                 | The path to the spec file or spec loaded via `OpenapiFirst.load` |

## Configuration

You can configure default options globally:

```ruby
OpenapiFirst.configure do |config|
  # Specify which plugin is used to render error responses returned by the request validation middleware (defaults to :default)
  config.request_validation_error_response = :json_api
  # Configure if the response validation middleware should raise an exception (defaults to false)
  config.request_validation_raise_error = true
end
```

## Development

Run `bin/setup` to install dependencies.

See `bundle exec rake` to run the linter and the tests.

Run `bundle exec rspec` to run the tests only.

### Benchmarks

[Results](https://gist.github.com/ahx/e6ffced58bd2e8d5baffb2f4d2c1f823)

Run benchmarks:

```sh
cd benchmarks
bundle
bundle exec ruby benchmarks.rb
```

### Contributing

If you have a question or an idea or found a bug don't hesitate to [create an issue](https://github.com/ahx/openapi_first/issues) or [start a discussion](https://github.com/ahx/openapi_first/discussions).

Pull requests are very welcome as well, of course. Feel free to create a "draft" pull request early on, even if your change is still work in progress. 🤗
