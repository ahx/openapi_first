# frozen_string_literal: true

RSpec.describe OpenapiFirst::Definition do
  def build_request(path, method: 'GET')
    Rack::Request.new(Rack::MockRequest.env_for(path, method:))
  end

  describe '#config' do
    it 'returns a frozen configuration' do
      definition = OpenapiFirst.load('./spec/data/petstore.yaml')
      expect(definition.config).to be_frozen
    end
  end

  describe '#inspect' do
    it 'returns a frozen configuration' do
      definition = OpenapiFirst.load('./spec/data/petstore.yaml')
      expect(definition.inspect).to eq("#<OpenapiFirst::Definition @key='./spec/data/petstore.yaml'>")
    end
  end

  describe '#[]' do
    it 'gives access to the raw hash' do
      definition = OpenapiFirst.load('./spec/data/train-travel-api/openapi.yaml')
      expect(definition['webhooks']).to be_a(Hash)
      expect(definition['webhooks'].dig('newBooking', 'post', 'operationId')).to eq('new-booking')
      expect(definition['components'].dig('schemas', 'Station', 'type')).to eq('object')
    end
  end

  describe '#key' do
    context 'when filepath is available' do
      it 'returns the filepath' do
        definition = OpenapiFirst.parse({
                                          'openapi' => '3.1.0',
                                          'paths' => {}
                                        }, filepath: '/path/to/openapi.yaml')

        expect(definition.key).to eq('/path/to/openapi.yaml')
      end
    end

    context 'when filepath is not available' do
      it 'generates a key from info.title and info.version' do
        definition = OpenapiFirst.parse({
                                          'openapi' => '3.1.0',
                                          'info' => {
                                            'title' => 'Test API',
                                            'version' => '1.0.0'
                                          },
                                          'paths' => {}
                                        })
        expect(definition.key).to eq('Test API @ 1.0.0')
      end
    end

    context 'when the OpenAPI document is missing info.title or info.version' do
      it 'raises an error' do
        definition = OpenapiFirst.parse({
                                          'openapi' => '3.1.0',
                                          'info' => {
                                            'title' => 'Test API'
                                            # Missing version
                                          },
                                          'paths' => {}
                                        })
        expect { definition.key }.to raise_error(ArgumentError, /Cannot generate key/)
      end
    end
  end

  describe '#paths' do
    it 'returns all paths' do
      definition = OpenapiFirst.load('./spec/data/petstore.yaml')
      expect(definition.paths).to eq(['/pets', '/pets/{petId}'])
    end
  end

  describe '#validate_request' do
    let(:definition_contents) do
      {
        'openapi' => '3.1.0',
        'paths' => {
          '/stuff/{id}' => {
            'get' => {
              'parameters' => [
                {
                  'name' => 'id',
                  'in' => 'path',
                  'required' => true,
                  'schema' => {
                    'type' => 'integer'
                  }
                }
              ]
            }
          }
        }
      }
    end

    let(:definition) do
      OpenapiFirst.parse(definition_contents)
    end

    context 'when request is valid' do
      let(:request) { build_request('/stuff/42') }

      it 'returns a valid request' do
        validated = definition.validate_request(request)
        expect(validated).to be_valid
        expect(validated.parsed_path_parameters).to eq({ 'id' => 42 })
      end
    end

    context 'when request is invalid' do
      let(:request) { build_request('/stuff/foo') }

      it 'returns an invalid request' do
        validated = definition.validate_request(request)
        expect(validated).not_to be_valid
        expect(validated.parsed_path_parameters).to eq({ 'id' => 'foo' })
      end

      it 'includes keys from json_schemer' do
        validated = definition.validate_request(request)
        expect(validated.error.errors).to contain_exactly(have_attributes(
                                                            value: 'foo',
                                                            data_pointer: '/id',
                                                            schema_pointer: '',
                                                            type: 'integer',
                                                            details: nil,
                                                            schema: { 'type' => 'integer' }
                                                          ))
      end

      context 'with raise_error: true' do
        it 'raises an error' do
          expect do
            definition.validate_request(request, raise_error: true)
          end.to raise_error(OpenapiFirst::RequestInvalidError)
        end

        it 'raises an error with access to the validated request' do
          expect do
            definition.validate_request(request, raise_error: true)
          end.to raise_error do |error|
            expect(error.request).to be_a(OpenapiFirst::ValidatedRequest)
            expect(error.request.path).to eq(request.path)
          end
        end
      end
    end

    context 'with a matching path and request method' do
      let(:definition) { OpenapiFirst.load('./spec/data/incompatible-routes.yaml') }
      let(:request) { Rack::Request.new(Rack::MockRequest.env_for('/foo/1')) }

      it 'is a known request' do
        expect(definition.validate_request(request)).to be_known
      end
    end

    context 'with different variables in common nested routes' do
      let(:definition) { OpenapiFirst.load('./spec/data/incompatible-routes.yaml') }

      it 'finds a match' do
        request = definition.validate_request(build_request('/foo/1'))
        expect(request.parsed_path_parameters).to eq({ 'fooId' => '1' })

        request = definition.validate_request(build_request('/foo/1/bar'))
        expect(request.parsed_path_parameters).to eq({ 'id' => '1' })

        request = definition.validate_request(build_request('/foo/special'))
        expect(request.parsed_path_parameters).to eq({})
      end
    end

    context 'with different patterns on the same path' do
      let(:definition) { OpenapiFirst.load('./spec/data/parameters-path.yaml') }

      it 'supports /{date}' do
        request = definition.validate_request(build_request('/info/2020-01-01'))
        operation_id = request.operation_id

        expect(operation_id).to eq 'info_date'
        expect(request.parsed_path_parameters['date']).to eq('2020-01-01')
      end

      it 'supports /{start_date}..{end_date}' do
        request = definition.validate_request(build_request('/info/2020-01-01..2020-01-02'))
        operation_id = request.operation_id
        expect(operation_id).to eq 'info_date_range'

        expect(request.parsed_path_parameters['start_date']).to eq('2020-01-01')
        expect(request.parsed_path_parameters['end_date']).to eq('2020-01-02')
      end

      it 'still works without parameters' do
        request = definition.validate_request(build_request('/info'))
        operation_id = request.operation_id
        expect(operation_id).to eq 'info'
        expect(request.parsed_path_parameters).to be_empty
      end
    end

    context 'with a matching path but unknown request method' do
      let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }
      let(:rack_request) { build_request('/pets', method: 'PATCH') }

      it 'has no request_definition' do
        expect(definition.validate_request(rack_request).request_definition).to be_nil
      end
    end

    context 'with SCRIPT_NAME' do
      let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }
      let(:rack_request) { Rack::Request.new(Rack::MockRequest.env_for('/42', script_name: '/pets')) }

      it 'respects SCRIPT_NAME to build the whole path' do
        validated = definition.validate_request(rack_request)
        expect(validated).to be_valid
        expect(validated.operation_id).to eq('showPetById')
      end
    end

    context 'with customized global JSONSchemer configuration' do
      before do
        JSONSchemer.configure do |config|
          config.formats = { 'pete' => ->(instance, _format) { instance == 'pete' } }
        end
      end

      let(:definition) do
        OpenapiFirst.parse({
                             'openapi' => '3.1.0',
                             'paths' => {
                               '/' => {
                                 'post' => {
                                   'requestBody' => {
                                     'content' => {
                                       'application/json' => {
                                         'schema' => {
                                           'type' => 'string',
                                           'format' => 'pete'
                                         }
                                       }
                                     }
                                   }
                                 }
                               }
                             }
                           })
      end

      it 'uses the global configuration' do
        request = Rack::Request.new(Rack::MockRequest.env_for('/', method: 'POST', input: '"bob"', 'CONTENT_TYPE' => 'application/json'))
        expect(
          definition.validate_request(request)
        ).not_to be_valid

        request = Rack::Request.new(Rack::MockRequest.env_for('/', method: 'POST', input: '"pete"', 'CONTENT_TYPE' => 'application/json'))
        expect(
          definition.validate_request(request, raise_error: true)
        ).to be_valid
      end
    end

    context 'with an alternate path used for schema matching' do
      let(:definition) do
        OpenapiFirst.parse(definition_contents) do |config|
          config.path = ->(req) { req.path.delete_prefix('/prefix') }
        end
      end

      it 'returns a valid request' do
        request = build_request('/prefix/stuff/42')
        validated = definition.validate_request(request)
        expect(validated).to be_valid
        expect(validated.parsed_path_parameters).to eq({ 'id' => 42 })
      end
    end
  end

  describe '#validate_response' do
    let(:definition_contents) do
      {
        'openapi' => '3.1.0',
        'paths' => {
          '/stuff' => {
            'get' => {
              'responses' => {
                '200' => {
                  'description' => 'OK',
                  'content' => {
                    'application/json' => {
                      'schema' => {
                        'type' => 'object',
                        'properties' => {
                          'id' => {
                            'type' => 'integer'
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    end

    let(:definition) do
      OpenapiFirst.parse(definition_contents)
    end

    let(:request) { build_request('/stuff') }

    context 'when response is valid' do
      let(:response) { Rack::Response.new(JSON.generate({ 'id' => 42 }), 200, { 'Content-Type' => 'application/json' }) }

      it 'returns a valid response' do
        validated = definition.validate_response(request, response)
        expect(validated).to be_valid
        expect(validated.parsed_body).to eq({ 'id' => 42 })
      end
    end

    context 'when response is invalid' do
      let(:response) { Rack::Response.new(JSON.generate({ 'id' => 'foo' }), 200, { 'Content-Type' => 'application/json' }) }

      it 'returns an invalid response' do
        validated = definition.validate_response(request, response)
        expect(validated).not_to be_valid
        expect(validated.parsed_body).to eq({ 'id' => 'foo' })
      end

      it 'includes keys from json_schemer' do
        validated = definition.validate_response(request, response)
        expect(validated.error.errors).to contain_exactly(have_attributes(
                                                            value: 'foo',
                                                            message: String,
                                                            data_pointer: '/id',
                                                            schema_pointer: '/properties/id',
                                                            type: 'integer',
                                                            details: nil,
                                                            schema: { 'type' => 'integer' }
                                                          ))
      end

      context 'with raise_error: true' do
        it 'raises an error' do
          expect do
            definition.validate_response(request, response, raise_error: true)
          end.to raise_error(OpenapiFirst::ResponseInvalidError)
        end
      end

      it 'raises an error with access to the validated request' do
        expect do
          definition.validate_response(request, response, raise_error: true)
        end.to raise_error do |error|
          expect(error.response).to be_a(OpenapiFirst::ValidatedResponse)
          expect(error.response.content_type).to eq(response.content_type)
        end
      end
    end

    context 'with an alternate path used for schema matching' do
      let(:definition) do
        OpenapiFirst.parse(definition_contents) do |config|
          config.path = ->(req) { req.path.delete_prefix('/prefix') }
        end
      end

      let(:response) { Rack::Response.new(JSON.generate({ 'id' => 42 }), 200, { 'Content-Type' => 'application/json' }) }

      it 'returns a valid response' do
        validated = definition.validate_response(request, response)
        expect(validated).to be_valid
        expect(validated.parsed_body).to eq({ 'id' => 42 })
      end
    end
  end

  describe '#routes' do
    let(:definition) { OpenapiFirst.load('./spec/data/train-travel-api/openapi.yaml') }

    it 'returns routes' do
      routes = definition.routes.map { |route| "#{route.request_method} #{route.path}" }
      expect(routes).to match_array ['GET /stations', 'GET /trips', 'GET /bookings', 'POST /bookings', 'GET /bookings/{bookingId}', 'DELETE /bookings/{bookingId}', 'POST /bookings/{bookingId}/payment']
    end

    it 'has a different key for each request and response' do
      requests_keys = definition.routes.flat_map { |route| route.requests.map(&:key) }
      expect(requests_keys.all?(Integer))
      expect(requests_keys.count).to eq(requests_keys.uniq.count)

      response_keys = definition.routes.flat_map { |route| route.responses.map(&:key) }
      expect(response_keys.all?(Integer))
      expect(response_keys.count).to eq(response_keys.uniq.count)

      expect((requests_keys + response_keys).uniq.count).to eq(requests_keys.count + response_keys.count)
    end
  end

  describe '#router' do
    let(:definition) { OpenapiFirst.load('./spec/data/train-travel-api/openapi.yaml') }

    it 'returns the router' do
      expect(definition.router).to be_a OpenapiFirst::Router
    end
  end

  describe '#filepath' do
    let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }

    it 'returns the path of the file' do
      expect(definition.filepath).to eq './spec/data/petstore.yaml'
    end

    context 'when initialized with a hash' do
      let(:definition) { OpenapiFirst::Definition.new(YAML.load_file('./spec/data/petstore.yaml')) }

      it 'returns nil' do
        expect(definition.filepath).to be_nil
      end
    end
  end
end
