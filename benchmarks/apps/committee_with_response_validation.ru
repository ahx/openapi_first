# frozen_string_literal: true

require 'json'
require 'committee'
require_relative 'app'

use Committee::Middleware::RequestValidation,
    schema_path: File.absolute_path('./openapi.yaml', __dir__),
    parse_response_by_content_type: true,
    strict_reference_validation: true

use Committee::Middleware::ResponseValidation,
    schema_path: File.absolute_path('./openapi.yaml', __dir__),
    strict: true,
    strict_reference_validation: true

run App
