# frozen_string_literal: true

module OpenapiFirst
  module Plugins
    module Jsonapi
      class ErrorResponse < OpenapiFirst::ErrorResponse
        def body
          MultiJson.dump({ errors: serialized_errors })
        end

        def content_type
          'application/vnd.api+json'
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
          case location
          when :body
            :pointer
          when :query, :path
            :parameter
          else
            location
          end
        end

        def pointer(data_pointer)
          return data_pointer if location == :body

          data_pointer.delete_prefix('/')
        end
      end
    end
  end
end
