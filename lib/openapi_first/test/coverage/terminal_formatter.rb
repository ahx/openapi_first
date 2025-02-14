# frozen_string_literal: true

module OpenapiFirst
  module Test
    module Coverage
      # This is the default formatter
      class TerminalFormatter
        # This takes a list of Coverage::Plan instances and outputs a String
        def format(coverage_result)
          @out = StringIO.new
          coverage_result.plans.each { |plan| format_plan(plan) }
          @out.string
        end

        private attr_reader :out

        private

        def puts(string)
          @out.puts(string)
        end

        def print(string)
          @out.print(string)
        end

        def format_plan(plan)
          filepath = plan.filepath
          puts ['', "API validation coverage for #{filepath}: #{plan.coverage}%"]
          return if plan.done?

          plan.routes.each do |route|
            next if route.finished?

            format_requests(route.requests)
            next if route.requests.none?(&:requested?)

            format_responses(route.responses)
          end
        end

        def format_requests(requests)
          requests.each do |request|
            if request.finished?
              puts green "✓ #{request_label(request)}"
            else
              puts red "❌ #{request_label(request)} – #{explain_unfinished_request(request)}"
            end
          end
        end

        def format_responses(responses)
          responses.each do |response|
            if response.finished?
              puts green "  ✓  #{response_label(response)}"
            else
              puts red "  ❌ #{response_label(response)} – #{explain_unfinished_response(response)}"
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

          'All requests invalid!' unless request.any_valid_request?
        end

        def response_label(response)
          name = +''
          name += response.status.to_s
          name += "(#{response.content_type})" if response.content_type
          name
        end

        def explain_unfinished_response(response)
          return 'No responses tracked!' unless response.responded?

          'All responses invalid!' unless response.any_valid_response?
        end
      end
    end
  end
end
