# frozen_string_literal: true

require 'fileutils'
require_relative 'html_reporter/context'

module OpenapiFirst
  module Test
    module Coverage
      # Writes a self-contained HTML coverage report to a file.
      class HtmlReporter
        include SkippedSummary

        def initialize(output: 'coverage/openapi_coverage.html', verbose: false, logger: Test.logger)
          @output = output
          @verbose = verbose
          @logger = logger
        end

        def report(coverage_result)
          html = TEMPLATE.result(Context.new(coverage_result, @verbose).get_binding)
          FileUtils.mkdir_p(File.dirname(@output))
          File.write(@output, html)
          coverage_result.plans.each do |plan|
            next if plan.coverage >= 100

            logger.info "API validation coverage for #{plan.api_identifier}: #{plan.coverage.round(4)}%"
          end
          log_skipped_summary(coverage_result)
          logger.info "API coverage report written to #{@output}"
        end

        private attr_reader :logger

        TEMPLATE_PATH = File.join(__dir__, 'html_reporter.html.erb')
        TEMPLATE = ERB.new(File.read(TEMPLATE_PATH), trim_mode: '-')
        TEMPLATE.filename = TEMPLATE_PATH
      end
    end
  end
end
