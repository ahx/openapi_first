# frozen_string_literal: true

module OpenapiFirst
  module Test
    module Coverage
      # Shared reporting of skipped requests and responses for coverage reporters.
      module SkippedSummary
        def log_skipped_summary(coverage_result)
          requests = coverage_result.skipped_requests_count
          responses = coverage_result.skipped_responses_count
          return if requests.zero? && responses.zero?

          logger.info "API coverage skipped #{requests} request(s) and #{responses} response(s)."
          return if requests.zero?

          logger.warn "#{requests} request(s) were skipped entirely. " \
                      'These requests are excluded from API coverage and are not contract-tested at all.'
        end
      end
    end
  end
end
