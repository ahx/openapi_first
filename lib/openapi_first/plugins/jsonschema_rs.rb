# frozen_string_literal: true

require_relative '../schema/jsonschema_rs_backend'

module OpenapiFirst
  module Plugins
    # Enables the faster, opt-in {OpenapiFirst::Schema::JsonschemaRsBackend} schema validation backend.
    #
    # The backend is global: it applies to all Definitions regardless of where it is configured. Because of
    # that, enabling it per definition (`OpenapiFirst.load(...) { |c| c.plugin :jsonschema_rs }`) is rejected
    # by ChildConfiguration#schema_backend= – it would silently affect everything. Enable it globally instead:
    #
    #   OpenapiFirst.plugin :jsonschema_rs
    #   # or
    #   OpenapiFirst.configure { |config| config.plugin :jsonschema_rs }
    module JsonschemaRs
      def self.configure(config, **)
        config.schema_backend = OpenapiFirst::Schema::JsonschemaRsBackend
      end
    end
  end
end
