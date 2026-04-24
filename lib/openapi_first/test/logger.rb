# frozen_string_literal: true

require 'logger'

module OpenapiFirst
  module Test
    # Logger to output coverage reports and such
    class Logger < ::Logger
      def initialize(*)
        super
        self.formatter = proc { |_severity, _time, _progname, msg|
          "#{msg}\n"
        }
      end
    end
  end
end
