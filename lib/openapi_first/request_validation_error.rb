# frozen_string_literal: true

module OpenapiFirst
  RequestValidationError = Struct.new(:status, :location, :schema_validation, keyword_init: true)

  class RequestValidationError
    TOPICS = {
      body: 'Request body invalid:',
      query: 'Query parameter invalid:',
      header: 'Header parameter invalid:',
      path: 'Path segment invalid:',
      cookie: 'Cookie value invalid:'
    }.freeze

    def message
      schema_validation&.message || Rack::Utils::HTTP_STATUS_CODES[status]
    end

    def error_message
      "#{TOPICS.fetch(location)} #{message}"
    end
  end
end
