# frozen_string_literal: true

module OpenapiFirst
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
        puts "API validation coverage for #{filepath}: #{plan.coverage}%"
        return if plan.done?

        plan.requests.each do |request|
          unless request.requested?
            puts red "#{format_request(request)} ❌ – Not requested!"
            next
          end
          puts green "#{format_request(request)} ✓"

          request.responses.each do |response|
            next if response.responded?

            print red "#{format_response(response)} ❌"
          end
        end
      end

      def green(text)
        "\e[32m#{text}\e[0m"
      end

      def red(text)
        "\e[31m#{text}\e[0m"
      end

      def format_request(request)
        name = "#{request.request_method.upcase} #{request.path}" # TODO: add required query parameters?
        name << " (#{request.content_type})" if request.content_type
        name
      end

      def format_response(response)
        name = "  #{response.status}"
        return(name + " (#{response.content_type})") if response.content_type

        name
      end
    end
  end
end
