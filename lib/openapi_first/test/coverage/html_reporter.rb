# frozen_string_literal: true

require 'fileutils'
require_relative 'html_reporter/context'

module OpenapiFirst
  module Test
    module Coverage
      # Writes a self-contained HTML coverage report to a file.
      class HtmlReporter
        def initialize(output: 'coverage/openapi_coverage.html', verbose: false, logger: Test.logger)
          @output = output
          @verbose = verbose
          @logger = logger
        end

        def report(coverage_result)
          html = TEMPLATE.result(Context.new(coverage_result, @verbose).get_binding)
          FileUtils.mkdir_p(File.dirname(@output))
          File.write(@output, html)
          @logger.info "API coverage report written to #{@output}"
        end

        TEMPLATE_PATH = File.join(__dir__, 'html_reporter.html.erb')
        TEMPLATE = ERB.new(File.read(TEMPLATE_PATH), trim_mode: '-')
        TEMPLATE.filename = TEMPLATE_PATH
      end
    end
  end
end
