# OpenapiFirst

[![Join the chat at https://gitter.im/openapi_first/community](https://badges.gitter.im/openapi_first/community.svg)](https://gitter.im/openapi_first/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

OpenapiFirst helps to implement HTTP APIs based on an [OpenApi](https://www.openapis.org/) API description. The idea is that you create an API description first, then add code that returns data and implements your business logic and be done.

Start with writing an OpenAPI file that describes the API, which you are about to implement. Use a [validator](https://github.com/stoplightio/spectral/) to make sure the file is valid.

OpenapiFirst consists of these Rack middlewares:

- [`OpenapiFirst::RequestValidation`](#OpenapiFirst::RequestValidation) – Validates the request against the API description and returns 400 if the request is invalid.
- [`OpenapiFirst::ResponseValidation`](#OpenapiFirst::ResponseValidation) Validates the response and raises an exception if the response body is invalid.
- [`OpenapiFirst::Router`](#OpenapiFirst::Router) – This internal middleware is added automatically when using request/response validation. It adds the OpenAPI operation for the current request to the Rack env or returns 404 if no operation was found.

## OpenapiFirst::RequestValidation

This middleware returns a 400 status code with a body that describes the error if the request is not valid.

```ruby
use OpenapiFirst::RequestValidation, spec: 'openapi.yaml'
```

This will add these fields to the Rack env:
- `env[OpenapiFirst::OPERATION]` – The Operation object for the current request. This is an instance of `OpenapiFirst::Operation`.
- `env[OpenapiFirst::PARAMS]` – The parsed parameters (query, path) for the current request (string keyed)
- `env[OpenapiFirst::REQUEST_BODY]` – The parsed request body (string keyed)

### Options and defaults

| Name           | Possible values | Description                                                                                        | Default                            |
| :------------- | --------------- | -------------------------------------------------------------------------------------------------- | ---------------------------------- |
| `spec:`        |                      | The path to the spec file or spec loaded via `OpenapiFirst.load`
| `raise_error:` | `false`, `true` | If set to true the middleware raises `OpenapiFirst::RequestInvalidError` instead of returning 4xx. | `false` (don't raise an exception) |

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

### Parameters


The `RequestValidation` middleware adds `env[OpenapiFirst::PARAMS]` (or `env['openapi.params']` ) with the converted query and path parameters. This only includes the parameters that are defined in the API description. It supports every [`style` and `explode` value as described](https://spec.openapis.org/oas/latest.html#style-examples) in the OpenAPI 3.0 and 3.1 specs. So you can do things these:

```ruby
# GET /pets/filter[id]=1,2,3
env[OpenapiFirst::PARAMS] # => { 'filter[id]' => [1,2,3] }

# GET /colors/.blue.black.brown?format=csv
env[OpenapiFirst::PARAMS] # => { 'color_names' => ['blue', 'black', 'brown'], 'format' => 'csv' }

# And a lot more.
```

Integration for specific webframeworks is ongoing. Don't hesitate to create an issue with you specific needs.

### Request body validation

This middleware adds the parsed request body to `env[OpenapiFirst::REQUEST_BODY]`.

The middleware will return a status `415` if the requests content type does not match or `400` if the request body is invalid.

### Header, Cookie, Path parameter validation

tbd.

### readOnly / writeOnly properties

Request validation fails if request includes a property with `readOnly: true`.

Response validation fails if response body includes a property with `writeOnly: true`.

## OpenapiFirst::ResponseValidation

This middleware is especially useful when testing. It _always_ raises an error if the response is not valid.


```ruby
use OpenapiFirst::ResponseValidation, spec: 'openapi.yaml' if ENV['RACK_ENV'] == 'test'
```

### Options

| Name           | Possible values      | Description                                                                                                                                                                                                                                                     | Default                            |
| :------------- | -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| `spec:`        |                      | The path to the spec file or spec loaded via `OpenapiFirst.load`

## OpenapiFirst::Router

This middleware is used automatically, but you can add it to the top of your middleware stack if you want to change configuration.

```ruby
use OpenapiFirst::Router, spec: './openapi/openapi.yaml'
```

This middleware adds `env[OpenapiFirst::OPERATION]` which holds an Operation object that responds to `#operation_id`, `#path` (and `#[string]` to access raw fields).

### Options and defaults

| Name           | Possible values      | Description                                                                                                                                                                                                                                                     | Default                            |
| :------------- | -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| `spec:`        |                      | The path to the spec file or spec loaded via `OpenapiFirst.load` |                                    |
| `raise_error:` | `false`, `true`      | If set to true the middleware raises `OpenapiFirst::NotFoundError` when a path or method was not found in the API description. This is useful during testing to spot an incomplete API description.                                                             | `false` (don't raise an exception) |
| `not_found:`   | `:continue`, `:halt` | If set to `:continue` the middleware will not return 404 (405, 415), but just pass handling the request to the next middleware or application in the Rack stack. If combined with `raise_error: true` `raise_error` gets preference and an exception is raised. | `:halt` (return 4xx response)      |

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
spec = OpenapiFirst.load('./openapi/openapi.yaml', only: { |path| path.starts_with? '/pets' })
run OpenapiFirst.app(spec, namespace: Pets)
```

## Development

Run `bin/setup` to install dependencies.

Run `bundle exec rspec` to run the tests.

See `bundle exec rake -T` for rubygems related tasks.

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
