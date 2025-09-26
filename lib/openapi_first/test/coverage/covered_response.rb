# frozen_string_literal: true

module OpenapiFirst
  module Test
    module Coverage
      CoveredResponse = Data.define(:key, :error) do
        def valid? = error.nil?
      end
    end
  end
end
