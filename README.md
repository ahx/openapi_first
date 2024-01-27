# openapi_first

OpenapiFirst helps to implement HTTP APIs based on an [OpenAPI](https://www.openapis.org/) API description. It supports OpenAPI 3.0 and 3.1. It offers request and response validation and it ensures that your implementation follows exactly the API description.

## Contents

<!-- TOC -->

- [Rack Middlewares](#rack-middlewares)
  - [Request validation](#request-validation)
  - [Response validation](#response-validation)
- [Manual use](#manual-use)
  - [Validate request](#validate-request)
  - [Validate response](#validate-response)
- [Configuration](#configuration)
- [Framework integration](#framework-integration)
- [Alternatives](#alternatives)
- [Development](#development)
  - [Benchmarks](#benchmarks)
  - [Contributing](#contributing)

<!-- /TOC -->

## Rack Middlewares

All middlewares add a _request_ object to the current Rack env at `env[OpenapiFirst::REQUEST]`), which is in an instance of `OpenapiFirst::RuntimeRequest` that responds to `.params`, `.parsed_body` etc.

This gives you access to the converted request parameters and body exaclty as described in your API description instead of relying on Rack alone to parse the request. This only includes query parameters that are defined in the API description. It supports every [`style` and `explode` value as described](https://spec.openapis.org/oas/latest.html#style-examples) in the OpenAPI 3.0 and 3.1 specs.

### Request validation

The request validation middleware returns a 4xx if the request is invalid or not defined in the API description.

```ruby
use OpenapiFirst::Middlewares::RequestValidation, spec: 'openapi.yaml'
```

#### Options

| Name              | Possible values                                                          | Description                                                                                                                         |
| :---------------- | ------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| `spec:`           |                                                                          | The path to the spec file or spec loaded via `OpenapiFirst.load`                                                                    |
| `raise_error:`    | `false` (default), `true`                                                | If set to true the middleware raises `OpenapiFirst::RequestInvalidError` or `OpenapiFirst::NotFoundError` instead of returning 4xx. |
| `error_response:` | `:default` (default), `:jsonapi`, Your implementation of `ErrorResponse` |

#### Error responses

openapi_first produces a useful machine readable error response that can be customized.
The default response looks like this. See also [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457).

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

openapi_first offers a [JSON:API](https://jsonapi.org/) error response as well:

```ruby
use OpenapiFirst::Middlewares::RequestValidation, spec: 'openapi.yaml, error_response: :jsonapi'
```

<details>
<summary>See details of JSON:API error response</summary>

```json
// http-status: 400
// content-type: "application/vnd.api+json"

{
  "errors": [
    {
      "status": "400",
      "source": {
        "pointer": "/data/name"
      },
      "title": "value at `/data/name` is not a string",
      "code": "string"
    },
    {
      "status": "400",
      "source": {
        "pointer": "/data/numberOfLegs"
      },
      "title": "number at `/data/numberOfLegs` is less than: 2",
      "code": "minimum"
    },
    {
      "status": "400",
      "source": {
        "pointer": "/data"
      },
      "title": "object at `/data` is missing required properties: mandatory",
      "code": "required"
    }
  ]
}
```

</details>

#### Custom error responses

You can build your own custom error response with `error_response: MyCustomClass` that implements `OpenapiFirst::ErrorResponse`.

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

## Manual use

Load the API description:

```ruby
require 'openapi_first'

definition = OpenapiFirst.load('openapi.yaml')
```

### Validate request

```ruby
# Find and validate request
rack_request = Rack::Request.new(env)
request = definition.validate_request(rack_request)
# Or raise an exception if validation fails:
request = definition.validate_request(rack_request, raise_error: true) # Raises OpenapiFirst::RequestInvalidError or OpenapiFirst::NotFoundError if request is invalid

# Inspect the request and access parsed parameters
request.known? # Is the request defined in the API description?
request.valid? # => true / false
request.error # => Failure object if request is invalid
request.body # alias: parsed_body
request.path_parameters # => { "pet_id" => 42 }
request.query # alias: query_parameters
request.params # Merged path and query parameters
request.headers
request.cookies
request.content_type
request.request_method # => "get"
request.path # => "/pets/42"
```

### Validate response

```ruby
# Find and validate the response
rack_response = Rack::Response[*app.call(env)]
response = definition.validate_response(rack_request, rack_response)

# Raise an exception if validation fails:
response = definition.validate_response(rack_request,rack_response, raise_error: true) # Raises OpenapiFirst::ResponseInvalidError or OpenapiFirst::ResponseNotFoundError
# Or you can also call a method on the request object mentioned above
request.validate_response(rack_response)

# Inspect the response and access parsed parameters and
response.known? # Is the response defined in the API description?
response.valid? # => true / false
response.error # => Failure object if response is invalid
response.body
request.headers
response.status # => 200
response.content_type
```

OpenapiFirst uses [`multi_json`](https://rubygems.org/gems/multi_json).

## Configuration

You can configure default options globally:

```ruby
OpenapiFirst.configure do |config|
  # Specify which plugin is used to render error responses returned by the request validation middleware (defaults to :default)
  config.request_validation_error_response = :jsonapi
  # Configure if the request validation middleware should raise an exception (defaults to false)
  config.request_validation_raise_error = true
end
```

## Framework integration

Using rack middlewares is supported in probably all Ruby web frameworks.
If you are using Ruby on Rails for example, you can add the request validation middleware globally in `config/application.rb` or inside specific controllers.

When running integration tests (or request specs when using rspec), it makes sense to add the response validation middleware to `config/environments/test.rb`:

```ruby
config.middleware.use OpenapiFirst::Middlewares::ResponseValidation,
  spec: 'api/openapi.yaml'
```

That way you don't have to call specific test assertions to make sure your API matches the OpenAPI document.
There is no need to run response validation on production if your test coverage is decent.

## Alternatives

This gem was inspired by [committe](https://github.com/interagent/committee) (Ruby) and [Connexion](https://github.com/spec-first/connexion) (Python).
Here is a [feature comparison between openapi_first and committee](https://gist.github.com/ahx/1538c31f0652f459861713b5259e366a).

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
