# frozen_string_literal: true

module OpenapiFirst
  module RequestValidationErrorMessage
    TOPICS = {
      body: 'Request body invalid:',
      query: 'Query parameter invalid:',
      header: 'Header parameter invalid:',
      path: 'Path segment invalid:',
      cookie: 'Cookie value invalid:'
    }.freeze

    def self.build(title, location)
      return title unless location

      "#{TOPICS.fetch(location)} #{title}"
    end
  end
end
