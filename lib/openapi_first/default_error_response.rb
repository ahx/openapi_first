# frozen_string_literal: true

module OpenapiFirst
  class DefaultErrorResponse < ErrorResponse
    OpenapiFirst::Plugins.register_error_response(:default, self)

    def body
      MultiJson.dump({ errors: serialized_errors })
    end

    def serialized_errors
      return default_errors unless validation_output

      key = pointer_key
      [
        {
          source: { key => pointer(validation_output['instanceLocation']) },
          title: validation_output['error']
        }
      ]
    end

    def default_errors
      [{
        status: status.to_s,
        title:
      }]
    end

    def pointer_key
      case location
      when :request_body
        :pointer
      when :query, :path
        :parameter
      else
        location
      end
    end

    def pointer(data_pointer)
      return data_pointer if location == :request_body

      data_pointer.delete_prefix('/')
    end
  end
end
