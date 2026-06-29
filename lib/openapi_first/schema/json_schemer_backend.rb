# frozen_string_literal: true

require 'json_schemer'

module OpenapiFirst
  module Schema
    # The default schema validation backend, powered by the {https://github.com/davishmcclurg/json_schemer json_schemer}
    # gem. It supports OpenAPI 3.0 and 3.1 and all features openapi_first relies on (the OpenAPI dialects,
    # readOnly/writeOnly enforcement, default insertion and the after_property_validation hook).
    #
    # See {OpenapiFirst::Schema::JsonschemaRsBackend} for the alternative, opt-in backend.
    class JsonSchemerBackend
      # OpenAPI versions this backend can validate.
      # @return [Array<String>]
      def self.supported_openapi_versions = %w[3.0 3.1]

      # @param document [Hash] The resolved OpenAPI document.
      # @param filepath [String, nil] The path the document was loaded from (used to resolve external $refs).
      # @param file_loader [OpenapiFirst::FileLoader] Loads referenced files from disk.
      def initialize(document:, filepath:, file_loader:)
        @file_loader = file_loader
        meta_schema = detect_meta_schema(document)
        @configuration = build_schemer_config(filepath:, meta_schema:)
      end

      # Build a schema validator for a node inside the document, keeping its $refs intact.
      # @param node [OpenapiFirst::RefResolver::Hash]
      # @param after_property_validation [Enumerable<#call>, nil] Hooks fired by json_schemer during traversal.
      # @return [LazySchema]
      def build_node(node, after_property_validation: nil)
        base_uri = URI::File.build({ path: "#{node.dir}/" })
        options = { configuration: @configuration }
        options[:after_property_validation] = after_property_validation if after_property_validation
        LazySchema.new(value: node.value, context: node.context, base_uri:, options:)
      end

      # Build a schema validator for a self-contained schema Hash (no external context).
      # @param schema [Hash]
      # @return [LazySchema]
      def build_inline(schema)
        LazySchema.new(value: schema, options: { configuration: @configuration })
      end

      private

      def build_schemer_config(filepath:, meta_schema:)
        result = JSONSchemer.configuration.clone
        dir = (filepath && File.absolute_path(File.dirname(filepath))) || Dir.pwd
        result.base_uri = URI::File.build({ path: "#{dir}/" })
        result.ref_resolver = JSONSchemer::CachedResolver.new do |uri|
          @file_loader.load(uri.path)
        end
        result.meta_schema = meta_schema
        result.insert_property_defaults = true
        result
      end

      def detect_meta_schema(document)
        # Copied from JSONSchemer 🙇🏻‍♂️
        if /\A3\.1\.\d+\z/.match?(document['openapi'])
          document.fetch('jsonSchemaDialect') { JSONSchemer::OpenAPI31::BASE_URI.to_s }
        else
          JSONSchemer::OpenAPI30::BASE_URI.to_s
        end
      end

      # Defers initialization of JSONSchemer::Schema, because that takes time.
      # @visibility private
      class LazySchema
        def initialize(value:, options:, context: nil, base_uri: nil)
          @value = value
          @context = context
          @base_uri = base_uri
          @options = options
        end

        # The raw schema Hash this validator was built from.
        attr_reader :value

        def validate(data, access_mode: nil)
          schema.validate(data, access_mode:)
        end

        def valid?(data)
          schema.valid?(data)
        end

        def schema
          @schema ||=
            if @context
              root_schema = JSONSchemer::Schema.new(@context, base_uri: @base_uri, **@options)
              JSONSchemer::Schema.new(@value, nil, root_schema, base_uri: @base_uri, **@options)
            else
              JSONSchemer.schema(@value, **@options)
            end
        end
      end
    end
  end
end
