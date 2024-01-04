# frozen_string_literal: true

module OpenapiFirst
  module Plugins
    module Default
      class ErrorResponse < OpenapiFirst::ErrorResponse
        def body
          MultiJson.dump({ errors: serialized_errors })
        end

        def content_type
          'application/json'
        end

        def serialized_errors
          return default_errors unless validation_output

          key = pointer_key
          validation_errors&.map do |error|
            {
              status: status.to_s,
              source: { key => pointer(error['instanceLocation']) },
              title: error['error']
            }
          end
        end

        def validation_errors
          validation_output['errors'] || [validation_output]
        end

        def default_errors
          [{
            status: status.to_s,
            title: message
          }]
        end

        def pointer_key
          case error_type
          when :invalid_body
            :pointer
          when :invalid_query, :invalid_path
            :parameter
          when :invalid_header
            :header
          when :invalid_cookie
            :cookie
          end
        end

        def pointer(data_pointer)
          return data_pointer if error_type == :invalid_body

          data_pointer.delete_prefix('/')
        end
      end
    end
  end
end
