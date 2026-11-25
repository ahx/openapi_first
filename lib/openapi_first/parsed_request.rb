# frozen_string_literal: true

module OpenapiFirst
  # @api private
  ParsedRequest = Data.define(:path, :query, :headers, :body, :cookies)
end
