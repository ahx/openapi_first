# frozen_string_literal: true

require 'rack'

# This example is a bit contrived, but it shows what you could do with the middlewares

App = Rack::Builder.new do
  spec = OpenapiFirst.load(File.expand_path('./openapi.yaml', __dir__))
  use(OpenapiFirst::Middlewares::RequestValidation, spec:)

  not_found = ->(_request) { [404, {}, []] }
  handlers = {
    'example#root' => lambda do |_request|
      [200, { Rack::CONTENT_TYPE => 'application/json' }, ['{"hello": "world"}']]
    end
  }
  handlers.default_proc = ->(_hash, _key) { not_found }

  run(lambda do |env|
    validated_request = env[OpenapiFirst::REQUEST]
    (handlers[validated_request.operation_id] || not_found).call(validated_request)
  end)
end


__END__
openapi: 3.0.0
info:
  title: "API"
  version: "1.0.0"
  contact:
    name: Contact Name
    email: contact@example.com
    url: https://example.com/
tags:
  - name: Metadata
    description: Metadata related requests
paths:
  /:
    get:
      operationId: things#index
      summary: Get metadata from the root of the API
      tags: ["Metadata"]
      responses:
        "200":
          description: OK
          content:
            application/json:
              schema:
                type: object
                required: [hello]
                properties:
                  hello:
                    type: string
