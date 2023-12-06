# Changelog

## Unreleased

- Add OpenapiFirst.configure
- Add OpenapiFirst.register, OpenapiFirst.plugin

## 1.0.0.beta6

- Fix: Make response header validation work with rack 3
- Refactor router
  - Remove dependency hanami-router
  - PathItem and Operation for a request can be found by calling methods on the Definitnion
- Fixed https://github.com/ahx/openapi_first/issues/155
- Breaking / Regression: A paths like /pets/{from}-{to} if there is a path "/pets/{id}"

## 1.0.0.beta5

- Added: `OpenapiFirst::Config.default_options=` to set default options globally
- Added: You can define custom error responses by subclassing `OpenapiFirst::ErrorResponse` and register it via `OpenapiFirst.register_error_response(name, MyCustomErrorResponse)`

## 1.0.0.beta4

- Update json_schemer to version 2.0
- Breaking: Requires Ruby 3.1 or later
- Added: Parameters are available at `env[OpenapiFirst::PATH_PARAMS]`, `env[OpenapiFirst::QUERY_PARAMS]`, `env[OpenapiFirst::HEADER_PARAMS]`, `env[OpenapiFirst::COOKIE_PARAMS]` in case you need to access them separately. Merged path and query parameters are still available at `env[OpenapiFirst::PARAMS]`
- Breaking / Added: ResponseValidation now validates response headers
- Breaking / Added: RequestValidation now validates cookie, path and header parameters
- Breaking: multipart File uploads are now read and then validated
- Breaking: Remove OpenapiFirst.env method
- Breaking: Request validation returns 400 instead of 415 if request body is required, but empty

## 1.0.0.beta3

- Remove obsolete dependency: deep_merge
- Remove obsolete dependency: hanami-utils

## 1.0.0.beta2

- Fixed dependencies. Remove unused code.

## 1.0.0.beta1

- Removed: `OpenapiFirst::Responder` and `OpenapiFirst::RackResponder`
- Removed: `OpenapiFirst.app` and `OpenapiFirst.middleware`
- Removed: `OpenapiFirst::Coverage`
- Breaking: Parsed query and path parameters are available at `env[OpenapiFirst::PARAMS]`(or `env['openapi.params']`) instead of `OpenapiFirst::PARAMETERS`.
- Breaking: Request body and parameters now use string keys instead of symbols!
- Breaking: Query parameters are now parsed exactly like in the API description via the openapi_parameters gem. This means a couple of things:
  - Query parameters now support `explode: true` (default) and `explode: false` for array and object parameters.
  - Query parameters with brackets like 'filter[tag]' are no longer deconstructed into nested hashes, but accessible via the `filter[tag]` key.
  - Query parameters are no longer interpreted as `style: deepObject` by default. If you want to use `style: deepObject`, for example to pass a nested hash as a query parameter like `filter[tag]`, you have to set `style: deepObject` explicitly.
- Path parameters are now parsed exactly as in the API description via the openapi_parameters gem.

## 0.21.0

- Fix: Query parameter validation does not fail if header parameters are defined (Thanks to [JF Lalonde](https://github.com/JF-Lalonde))
- Update Ruby dependency to >= 3.0.5
- Handle simple form-data in request bodies (see https://github.com/ahx/openapi_first/issues/149)
- Update to hanami-router 2.0.0 stable

## 0.20.0

- You can pass a filepath to `spec:` now so you no longer have to call `OpenapiFirst.load` anymore.
- Router is optional now.
  You no longer have to add `Router` to your middleware stack. You still can add it to customize behaviour by setting options, but you no longer have to add it.
  If you don't add the Router, make sure you pass `spec:` to your request/response validation middleware.
- Support "4xx" and "4XX" response definitions.
  (4XX is defined in the standard, but 2xx is used in the wild as well 🦁.)
- Removed warning about missing operationId, because operationId is not used until the Responder is used.
- Raise HandlerNotFoundError when handler cannot be found

## 0.19.0

- Add `RackResponder`

- BREAKING CHANGE: Handler classes are now instantiated only once without any arguments and the same instance is called on each following call/request.

## 0.18.0

Yanked. No useful changes.

## 0.17.0

- BREAKING CHANGE: Use a Hash instead of named arguments for middleware options for better compatibility
  Using named arguments is actually not supported in Rack.

## 0.16.1

- Pin hanami-router version, because alpha6 is broken.

## 0.16.0

- Support status code wildcards like "2XX", "4XX"

## 0.15.0

- Populate default parameter values

## 0.14.3

- Use json_refs to resolve OpenAPI file. This removes oas_parser and ActiveSupport from list of dependencies

## 0.14.2

- Empty query parameters are parsed and request validation returns 400 if an empty string is not allowed. Note that this does not look at `allowEmptyValue` in any way, because allowEmptyValue is deprecated.

## 0.14.1

- Fix: Don't mix path- and operation-level parameters for request validation

## 0.14.0

- Handle custom x-handler field in the API description to find a handler method not based on operationId
- Add `resolver` option to provide a custom resolver to find a handler method

## 0.13.3

- Better error message if string does not match format
- readOnly and writeOnly just works when used inside allOf

## 0.13.2

- Return indicator (`source: { parameter: 'list/1' }`) in error response body when array item in query parameter is invalid

## 0.13.0

- Add support for arrays in query parameters (style: form, explode: false)
- Remove warning when handler is not implemented

## 0.12.5

- Add `not_found: :continue` option to Router to make it do nothing if request is unknown

## 0.12.4

- content-type is found while ignoring additional content-type parameters (`application/json` is found when request/response content-type is `application/json; charset=UTF8`)
- Support wildcard mime-types when finding the content-type

## 0.12.3

- Add `response_validation:`, `router_raise_error` options to standalone mode.

## 0.12.2

- Allow response to have no media type object specified

## 0.12.1

- Fix response when handler returns 404 or 405
- Don't validate the response content if status is 204 (no content)

## 0.12.0

- Change `ResponseValidator` to raise an exception if it found a problem
- Params have symbolized keys now
- Remove `not_found` option from Router. Return 405 if HTTP verb is not allowed (via Hanami::Router)
- Add `raise_error` option to OpenapiFirst.app (false by default)
- Add ResponseValidation to OpenapiFirst.app if raise_error option is true
- Rename `raise` option to `raise_error`
- Add `raise_error` option to RequestValidation middleware
- Raise error if handler could not be found by Responder
- Add `Operation#name` that returns a human readable name for an operation

## 0.11.0

- Raise error if you forgot to add the Router middleware
- Make OpenapiFirst.app raise an error in test env when request path is not specified
- Rename OperationResolver to Responder
- Add ResponseValidation middleware that validates the response body
- Add `raise` option to Router middleware to raise an error if request could not be found in the API description similar to committee's raise option.
- Move namespace option from Router to OperationResolver

## 0.10.2

- Return 400 if request body has invalid JSON ([issue](https://github.com/ahx/openapi_first/issues/73)) thanks Thomas Frütel

## 0.10.1

- Fix duplicated key in `required` when generating JSON schema for `some[thing]` parameters

## 0.10.0

- Add support for query parameters named `"some[thing]"` ([issue](https://github.com/ahx/openapi_first/issues/40))

## 0.9.0

- Make request validation usable standalone

## 0.8.0

- Add merged parameter and request body available to env at `env[OpenapiFirst::INBOX]` in request validation
- Path and query parameters with `type: boolean` now get converted to `true`/`false`
- Rename `OpenapiFirst::PARAMS` to `OpenapiFirst::PARAMETERS`

## 0.7.1

- Add missing `require` to work with new version of `oas_parser`

## 0.7.0

- Make use of hanami-router, because it's fast
- Remove option `allow_unknown_query_paramerters`
- Move the namespace option to Router
- Convert numeric path and query parameters to `Integer` or `Float`
- Pass the Rack env if your action class' initializers accepts an argument
- Respec rack's `env['SCRIPT_NAME']` in router
- Add MIT license

## 0.6.10

- Bugfix: params.env['unknown'] now returns `nil` as expected. Thanks @tristandruyen.

## 0.6.9

- Removed radix tree, because of a bug (https://github.com/namusyaka/r2ree-ruby/issues/2)

## 0.6.8

- Performance: About 25% performance increase (i/s) with help of c++ based radix-tree and some optimizations
- Update dependencies

## 0.6.7

- Fix: version number of oas_parser

## 0.6.6

- Remove warnings for Ruby 2.7

## 0.6.5

- Merge QueryParameterValidation and ReqestBodyValidation middlewares into RequestValidation
- Rename option to `allow_unknown_query_paramerters`

## 0.6.4

- Fix: Rewind request body after reading

## 0.6.3

- Add option to parse only certain paths from OAS file

## 0.6.2

- Add support to map operationIds like `things#index` or `web.things_index`

## 0.6.1

- Make ResponseValidator errors easier to read

## 0.6.0

- Set the content-type based on the OpenAPI description [#29](https://github.com/ahx/openapi-first/pull/29)
- Add CHANGELOG 📝
