# frozen_string_literal: true

module OpenapiFirst
  ParsedRequest = Data.define(:path, :query, :headers, :body, :cookies)
end
