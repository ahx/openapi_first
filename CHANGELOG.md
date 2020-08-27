# Changelog

## Unreleased
- Add support for arrays in query parameters (form style, explode: false only)

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
- Don't validate the response content if status is 205 (no content)

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
- Convert numeric path and query parameters  to `Integer` or `Float`
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
