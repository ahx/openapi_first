# frozen_string_literal: true

require 'multi_json'

module OpenapiFirst
  # @!visibility private
  class BodyParser
    def initialize(content_type)
      @is_json = :json if /json/i.match?(content_type)
    end

    def parse(request)
      body = read_body(request)
      return if body.empty?

      return MultiJson.load(body) if @is_json
      return request.POST if request.form_data?

      body
    rescue MultiJson::ParseError
      Failure.fail!(:invalid_body, message: 'Failed to parse request body as JSON')
    end

    private

    def read_body(request)
      body = request.body.read
      request.body.rewind
      body
    end
  end
end
