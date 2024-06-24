# openapi_first

OpenapiFirst helps to implement HTTP APIs based on an [OpenAPI](https://www.openapis.org/) API description. It supports OpenAPI 3.0 and 3.1. It offers request and response validation and it ensures that your implementation follows exactly the API description.

## Contents

<!-- TOC -->

- [Rack Middlewares](#rack-middlewares)
  - [Request validation](#request-validation)
  - [Response validation](#response-validation)
- [Test assertions](#test-assertions)
- [Manual use](#manual-use)
  - [Validate request](#validate-request)
  - [Validate response](#validate-response)
- [Framework integration](#framework-integration)
- [Configuration](#configuration)
- [Hooks](#hooks)
- [Alternatives](#alternatives)
- [Development](#development)
  - [Benchmarks](#benchmarks)
  - [Contributing](#contributing)

<!-- /TOC -->

## Rack Middlewares

### Request validation

The request validation middleware returns a 4xx if the request is invalid or not defined in the API description. It adds a request object to the current Rack environment at `env[OpenapiFirst::REQUEST]` with the request parameters parsed exaclty as described in your API description plus access to meta information from your API description. See _[Manual use](#manual-use)_ for more details about that object.

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
You can define custom error responses globally by including / implementing `OpenapiFirst::ErrorResponse` and register it via `OpenapiFirst.register_error_response(my_name, MyCustomErrorResponse)` and set `error_response: my_name`.

#### readOnly / writeOnly properties

Request validation fails if request includes a property with `readOnly: true`.

Response validation fails if response body includes a property with `writeOnly: true`.

### Response validation

This middleware is especially useful when testing. It raises an error by default if the response is not valid.

```ruby
use OpenapiFirst::Middlewares::ResponseValidation, spec: 'openapi.yaml' if ENV['RACK_ENV'] == 'test'
```

#### Options

| Name    | Possible values | Description                                                      |
| :------ | --------------- | ---------------------------------------------------------------- |
| `spec:` |                 | The path to the spec file or spec loaded via `OpenapiFirst.load` |
| `raise_error:`    | `true` (default), `false`                                                | If set to true the middleware raises `OpenapiFirst::ResponseInvalidError` or `OpenapiFirst::ResonseNotFoundError` if the response does not match the API description. |

## Test assertions

openapi_first ships with a simple but powerful Test module to run request and response validation in your tests without using the middlewares. This is designed to be used with rack-test or Ruby on Rails integration tests or request specs.

Here is how to set it up for Rails integration tests:

```ruby
# test_helper.rb
require 'openapi_first/test'
OpenapiFirst::Test.register('openapi/v1.openapi.yaml')
```

Inside your test:
```ruby
# test/integration/trips_api_test.rb
require 'test_helper'

class TripsApiTest < ActionDispatch::IntegrationTest
  include OpenapiFirst::Test::Methods

  test 'GET /trips' do
    get '/trips',
        params: { origin: 'efdbb9d1-02c2-4bc3-afb7-6788d8782b1e', destination: 'b2e783e1-c824-4d63-b37a-d8d698862f1d',
                  date: '2024-07-02T09:00:00Z' }

    assert_api_conform(status: 200)
  end
end
```

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
validated_request = definition.validate_request(rack_request)
# Or raise an exception if validation fails:
definition.validate_request(rack_request, raise_error: true) # Raises OpenapiFirst::RequestInvalidError or OpenapiFirst::NotFoundError if request is invalid

# Inspect the request and access parsed parameters
validated_request.known? # Is the request defined in the API description?
validated_request.valid? # => true / false
validated_request.invalid? # => true / false
validated_request.error # => Failure object if request is invalid
validated_request.parsed_params # Merged parsed path, query parameters and request body
validated_request.parsed_body
validated_request.parsed_path_parameters # => { "pet_id" => 42 }
validated_request.parsed_headers
validated_request.parsed_cookies
validated_request.parsed_query

# Access the Openapi 3 Operation Object Hash
validated_request.operation['x-foo']
validated_request.operation['operationId']
# or the whole request definition
validated_request.request_definition.path # => "/pets/{petId}"
validated_request.request_definition.operation_id # => "showPetById"
```

### Validate response

```ruby
# Find and validate the response
rack_response = Rack::Response[*app.call(env)]
validated_response = definition.validate_response(rack_request, rack_response)

# Raise an exception if validation fails:
definition.validate_response(rack_request,rack_response, raise_error: true) # Raises OpenapiFirst::ResponseInvalidError or OpenapiFirst::ResponseNotFoundError

# Inspect the response and access parsed parameters and
response.known? # Is the response defined in the API description?
response.valid? # => true / false
response.invalid? # => true / false
response.error # => Failure object if response is invalid
response.status # => 200
response.parsed_body
response.parsed_headers
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

or configure per instance:

```ruby
OpenapiFirst.load('openapi.yaml') do |config|
  config.request_validation_error_response = :jsonapi
end
```

## Hooks

You can integrate your code at certain points during request/response validation via hooks.

Available hooks:

- `after_request_validation`
- `after_response_validation`
- `after_request_parameter_property_validation`
- `after_request_body_property_validation`

Setup per per instance:

```ruby
OpenapiFirst.load('openapi.yaml') do |config|
  config.after_request_validation do |validated_request|
    validated_request.valid? # => true / false
  end
  config.after_response_validation do |validated_response, request|
    if validated_response.invalid?
      warn "#{request.request_method} #{request.path}: #{validated_response.error.message}"
    end
  end
end
```

Setup globally:

```ruby
OpenapiFirst.configure do |config|
  config.after_request_parameter_property_validation do |data, property, property_schema|
    data[property] = Date.iso8601(data[property]) if propert_schema['format'] == 'date'
  end
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
