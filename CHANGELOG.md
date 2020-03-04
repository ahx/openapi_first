# Changelog

## Unreleased
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
