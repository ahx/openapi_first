# frozen_string_literal: true

require 'json'
require 'openapi_first'
require_relative 'app'

use OpenapiFirst::Middlewares::RequestValidation, spec: File.absolute_path('./openapi.yaml', __dir__)
run App
