# frozen_string_literal: true

module OpenapiFirst
  # Finds the request objects that matches the content type.
  class ContentMatcher
    def initialize(requests)
      @requests = requests.each_with_object({}) do |req, result|
        result[req.content_type] = req
      end
    end

    def call(content_type)
      @requests.fetch(content_type) do
        type = content_type.split(';')[0]
        @requests[type] || @requests["#{type.split('/')[0]}/*"] || @requests['*/*']
      end
    end
  end
end
