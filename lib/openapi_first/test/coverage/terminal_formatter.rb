# frozen_string_literal: true

module OpenapiFirst
  module Test
    module Coverage
      # This is the default formatter
      class TerminalFormatter
        # This takes a list of Coverage::Plan instances and outputs a String
        def format(plans)
          @out = StringIO.new
          plans.each { |plan| format_plan(plan) }
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

          plan.requests.each do |request|
            if request.requested?
              if request.responses.all?(&:finished?)
                puts green "✓ #{request_label(request)}"
              else
                puts orange "⚠ #{request_label(request)}"
              end
            else
              puts red "❌ #{request_label(request)} – Not requested!"
              next
            end

            request.responses.each do |response|
              if response.responded?
                # puts green "  ✓ #{response_label(response)}"
                next
              end

              puts red "  ❌ #{response_label(response)}"
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

        def response_label(response)
          name = response.status.to_s
          return(name + " (#{response.content_type})") if response.content_type

          name
        end
      end
    end
  end
end
