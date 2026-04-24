# frozen_string_literal: true

module OpenapiFirst
  module Test
    module Coverage
      # This is the default formatter
      class TerminalFormatter
        def initialize(verbose: false, focused: true, logger: Test.logger)
          @verbose = verbose
          @focused = focused && !verbose
          @logger = logger
        end

        def format(coverage_result)
          warn 'DEPRECATION WARNING: TerminalFormatter#format is deprecated, use #report instead.'
          report(coverage_result)
        end

        def report(coverage_result)
          coverage = coverage_result.coverage
          if coverage.zero?
            logger.warn 'API Coverage did not detect any API requests for the registered API descriptions. ' \
                        'Make sure to observe your application using OpenapiFirst::Test.'
          end
          coverage_result.plans.each { |plan| format_plan(plan) } if coverage.positive?
        end

        private attr_reader :out, :verbose, :focused, :logger, :is_tty

        private

        def format_plan(plan) # rubocop:disable Metrics/PerceivedComplexity
          logger.info "API validation coverage for #{plan.api_identifier}: #{plan.coverage}%"
          return if plan.done? && !verbose

          requested_routes_count = plan.routes.count { |route| route.requests.any?(&:requested?) }
          focused_route = requested_routes_count <= 1 && focused

          plan.routes.each do |route|
            next if route.finished? && !verbose

            next if route.requests.none?(&:requested?) && focused_route

            format_requests(route.requests)

            format_responses(route.responses)
          end
        end

        def format_requests(requests)
          requests.each do |request|
            if request.finished?
              log_success "✓ #{request_label(request)}"
            else
              log_error "❌ #{request_label(request)} – #{explain_unfinished_request(request)}"
            end
          end
        end

        def format_responses(responses)
          responses.each do |response|
            if response.finished?
              log_success "  ✓  #{response_label(response)}" if verbose
            else
              log_error "  ❌ #{response_label(response)} – #{explain_unfinished_response(response)}"
            end
          end
        end

        def green(text)
          "\e[32m#{text}\e[0m"
        end

        def red(text)
          "\e[31m#{text}\e[0m"
        end

        def orange(text)
          "\e[33m#{text}\e[0m"
        end

        def request_label(request)
          name = "#{request.request_method.upcase} #{request.path}" # TODO: add required query parameters?
          name << " (#{request.content_type})" if request.content_type
          name
        end

        def explain_unfinished_request(request)
          return 'No requests tracked!' unless request.requested?

          return if request.any_valid_request?

          "All requests invalid! (#{request.last_error_message.inspect})"
        end

        def response_label(response)
          name = +''
          name += response.status.to_s
          name += "(#{response.content_type})" if response.content_type
          name
        end

        def explain_unfinished_response(response)
          return 'No responses tracked!' unless response.responded?

          "All responses invalid! (#{response.last_error_message.inspect})" unless response.any_valid_response?
        end

        def log_success(msg)
          logger.info "\e[32m#{msg}\e[0m"
        end

        def log_error(msg)
          logger.error "\e[31m#{msg}\e[0m"
        end
      end
    end
  end
end
