# Changelog

## Unreleased
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
