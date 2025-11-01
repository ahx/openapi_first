# frozen_string_literal: true

require 'json'
require 'openapi_first'
require_relative 'app'

OpenapiFirst.register File.absolute_path('./openapi.yaml', __dir__), as: :v1

use OpenapiFirst::Middlewares::RequestValidation, :v1
use OpenapiFirst::Middlewares::ResponseValidation, :v1

run App
