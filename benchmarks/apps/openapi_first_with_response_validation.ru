# frozen_string_literal: true

require 'json'
require 'openapi_first'
require_relative 'app'

OpenapiFirst.register File.absolute_path('./openapi.yaml', __dir__)

use OpenapiFirst::Middlewares::RequestValidation
use OpenapiFirst::Middlewares::ResponseValidation

run App
