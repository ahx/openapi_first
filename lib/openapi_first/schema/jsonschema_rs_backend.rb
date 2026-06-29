# frozen_string_literal: true

require 'jsonschema_rs'

module OpenapiFirst
  module Schema
    # An opt-in schema validation backend powered by the {https://rubygems.org/gems/jsonschema_rs jsonschema_rs}
    # gem (a Ruby binding to the Rust `jsonschema` crate). It is significantly faster than the default
    # {OpenapiFirst::Schema::JsonSchemerBackend}, but only supports OpenAPI 3.1 (which is JSON-Schema-2020-12
    # compatible). OpenAPI 3.0 is not standard JSON Schema and is rejected at load time.
    #
    # Enable it globally:
    #   OpenapiFirst.plugin :jsonschema_rs
    class JsonschemaRsBackend
      # The key under which a node's subtree is injected into a copy of its document so that internal $refs
      # resolve against the whole document while validation runs against just the subtree.
      SUBJECT_KEY = 'x-openapi-first-subject'

      # OpenAPI versions this backend can validate. 3.0 is unsupported (see class docs).
      # @return [Array<String>]
      def self.supported_openapi_versions = %w[3.1]

      # @param document [Hash] The resolved OpenAPI document (unused; accepted for backend interface parity).
      # @param filepath [String, nil] Unused; accepted for backend interface parity (per-node paths come from the node).
      # @param file_loader [OpenapiFirst::FileLoader] Loads referenced files from disk.
      def initialize(document:, filepath:, file_loader:) # rubocop:disable Lint/UnusedMethodArgument
        @file_loader = file_loader
      end

      # Build a schema validator for a node inside the document, keeping its $refs intact.
      # @param node [OpenapiFirst::RefResolver::Hash]
      # @param after_property_validation [Enumerable<#call>, nil]
      # @return [Validator]
      def build_node(node, after_property_validation: nil)
        Validator.new(
          raw: node.value,
          file_loader: @file_loader,
          context: node.context,
          filepath: node.filepath,
          dir: node.dir,
          properties: top_level_properties(node),
          after_property_validation:
        )
      end

      # Build a schema validator for a self-contained schema Hash (no external context).
      # @param schema [Hash]
      # @return [Validator]
      def build_inline(schema)
        Validator.new(raw: schema, file_loader: @file_loader)
      end

      private

      def top_level_properties(node)
        node.resolved['properties'] || {}
      end

      # Wraps a compiled jsonschema_rs validator and adapts it to the openapi_first backend interface.
      # @visibility private
      class Validator
        def initialize(raw:, file_loader:, context: nil, filepath: nil, dir: nil, properties: nil,
                       after_property_validation: nil)
          @raw = raw
          @file_loader = file_loader
          @context = context
          @filepath = filepath
          @dir = dir
          @properties = properties
          @after_property_validation = after_property_validation
        end

        # The raw schema Hash this validator was built from (used for default insertion).
        # @return [Hash]
        def value = @raw

        def valid?(data)
          validator.valid?(prepare(data))
        end

        # @return [Array<Hash>] json_schemer-shaped error Hashes.
        def validate(data, access_mode: nil)
          prepared = prepare(data)
          errors = []
          validator.each_error(prepared) do |error|
            next if access_mode && suppress_required?(error, access_mode)

            errors << map_error(error)
          end
          errors.concat(access_mode_errors(prepared, access_mode)) if access_mode
          errors
        end

        private

        def validator
          @validator ||= JSONSchema.validator_for(compiled_schema, **compile_options)
        end

        def compile_options
          options = { validate_formats: true }
          options[:retriever] = retriever if @context
          options
        end

        # When the schema lives inside a document, validate against a $ref into a copy of that document so
        # internal, nested and recursive $refs resolve. Self-contained schemas compile directly.
        def compiled_schema
          return @raw unless @context

          { '$ref' => "#{document_uri}#/#{SUBJECT_KEY}" }
        end

        def document_uri
          @document_uri ||=
            if @filepath
              "file://#{File.absolute_path(@filepath)}"
            else
              "file://#{@dir}/openapi-first-document"
            end
        end

        def served_document
          @served_document ||= @context.dup.tap { |doc| doc[SUBJECT_KEY] = @raw }
        end

        def retriever
          documents = { document_uri => served_document }
          lambda do |uri|
            uri = uri.to_s
            documents[uri] || load_external(uri)
          end
        end

        def load_external(uri)
          raise ArgumentError, "Unsupported reference URI: #{uri}" unless uri.start_with?('file://')

          @file_loader.load(uri.delete_prefix('file://'))
        end

        # Insert top-level property defaults and fire after_property_validation hooks, mirroring (at the top
        # level) what json_schemer does during traversal. Mutates and returns +data+.
        def prepare(data)
          return data unless @properties && data.is_a?(::Hash)

          insert_defaults(data)
          fire_after_property_validation(data)
          data
        end

        def insert_defaults(data)
          @properties.each do |name, subschema|
            next unless subschema.is_a?(::Hash) && subschema.key?('default')

            data[name] = subschema['default'] unless data.key?(name)
          end
        end

        def fire_after_property_validation(data)
          return unless @after_property_validation&.any?

          @properties.each do |name, subschema|
            next unless data.key?(name)

            @after_property_validation.each { |hook| hook.call(data, name, subschema, nil) }
          end
        end

        # In write access mode a readOnly property and in read access mode a writeOnly property is not required,
        # so suppress the corresponding top-level `required` error.
        def suppress_required?(error, access_mode)
          return false unless error.kind.name == 'required'

          subschema = @properties[error.kind.value[:property]]
          subschema.is_a?(::Hash) && subschema[access_mode == 'write' ? 'readOnly' : 'writeOnly'] == true
        end

        # A readOnly property must not appear in a request body (write) and a writeOnly property must not appear
        # in a response body (read). jsonschema_rs surfaces readOnly/writeOnly as annotations on present
        # properties, which we turn into errors at every depth.
        def access_mode_errors(data, access_mode)
          flag = access_mode == 'write' ? 'readOnly' : 'writeOnly'
          validator.evaluate(data).annotations.filter_map do |annotation|
            values = annotation[:annotations]
            next unless values.is_a?(::Hash) && values[flag] == true

            {
              'data' => nil,
              'data_pointer' => annotation[:instanceLocation],
              'schema_pointer' => annotation[:schemaLocation],
              'type' => flag,
              'details' => nil,
              'schema' => { flag => true }
            }
          end
        end

        def map_error(error)
          type, details, schema = translate(error.kind)
          {
            'data' => error.instance,
            'data_pointer' => error.instance_path_pointer,
            'schema_pointer' => error.schema_path_pointer,
            'type' => type,
            'details' => details,
            'schema' => schema
          }
        end

        # Map jsonschema_rs's generic error kinds to json_schemer's keyword vocabulary, reconstructing the
        # minimal schema/details that {OpenapiFirst::Schema::ValidationError#message} needs.
        def translate(kind)
          value = kind.value
          case kind.name
          when 'type'
            types = value[:types]
            single = types.length == 1
            [single ? types.first : 'type', nil, { 'type' => single ? types.first : types }]
          when 'required'
            ['required', { 'missing_keys' => [value[:property]] }, nil]
          when 'pattern' then ['pattern', nil, { 'pattern' => value[:pattern] }]
          when 'format' then ['format', nil, { 'format' => value[:format] }]
          when 'const' then ['const', nil, { 'const' => value[:expected_value] }]
          when 'enum' then ['enum', nil, { 'enum' => value[:options] }]
          when 'minimum' then ['minimum', nil, { 'minimum' => value[:limit] }]
          when 'maximum' then ['maximum', nil, { 'maximum' => value[:limit] }]
          else [kind.name, nil, nil]
          end
        end
      end
    end
  end
end
