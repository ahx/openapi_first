# frozen_string_literal: true

RSpec.describe OpenapiFirst::Doc do
  def build_request(path, method: 'GET')
    Rack::Request.new(Rack::MockRequest.env_for(path, method:))
  end

  describe '#config' do
    it 'returns a frozen configuration' do
      definition = OpenapiFirst.load('./spec/data/petstore.yaml')
      expect(definition.config).to be_frozen
    end
  end

  describe '#paths' do
    it 'returns all paths' do
      definition = OpenapiFirst.load('./spec/data/petstore.yaml')
      expect(definition.paths).to eq(['/pets', '/pets/{petId}'])
    end
  end

  describe '#validate_request' do
    let(:definition) do
      OpenapiFirst.parse({
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
                         })
    end

    context 'when request is valid' do
      let(:request) { build_request('/stuff/42') }

      it 'returns a valid request' do
        validated = definition.validate_request(request)
        expect(validated).to be_valid
        expect(validated.path_parameters).to eq({ 'id' => 42 })
      end
    end

    context 'when request is invalid' do
      let(:request) { build_request('/stuff/foo') }

      it 'returns an invalid request' do
        validated = definition.validate_request(request)
        expect(validated).not_to be_valid
        expect(validated.path_parameters).to eq({ 'id' => 'foo' })
      end

      it 'raises an error with raise_error: true' do
        expect do
          definition.validate_request(request, raise_error: true)
        end.to raise_error(OpenapiFirst::RequestInvalidError)
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
        expect(request.path_parameters).to eq({ 'fooId' => '1' })

        request = definition.validate_request(build_request('/foo/1/bar'))
        expect(request.path_parameters).to eq({ 'id' => '1' })

        request = definition.validate_request(build_request('/foo/special'))
        expect(request.path_parameters).to eq({})
      end
    end

    context 'with different patterns on the same path' do
      let(:definition) { OpenapiFirst.load('./spec/data/parameters-path.yaml') }

      it 'supports /{date}' do
        request = definition.validate_request(build_request('/info/2020-01-01'))
        operation_id = request.operation_id

        expect(operation_id).to eq 'info_date'
        expect(request.path_parameters['date']).to eq('2020-01-01')
      end

      it 'supports /{start_date}..{end_date}' do
        request = definition.validate_request(build_request('/info/2020-01-01..2020-01-02'))
        operation_id = request.operation_id
        expect(operation_id).to eq 'info_date_range'

        expect(request.path_parameters['start_date']).to eq('2020-01-01')
        expect(request.path_parameters['end_date']).to eq('2020-01-02')
      end

      it 'still works without parameters' do
        request = definition.validate_request(build_request('/info'))
        operation_id = request.operation_id
        expect(operation_id).to eq 'info'
        expect(request.path_parameters).to be_empty
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
  end

  describe '#validate_response' do
    let(:definition) do
      OpenapiFirst.parse({
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
                         })
    end

    let(:request) { build_request('/stuff') }

    context 'when response is valid' do
      let(:response) { Rack::Response.new(JSON.dump({ 'id' => 42 }), 200, { 'Content-Type' => 'application/json' }) }

      it 'returns a valid response' do
        validated = definition.validate_response(request, response)
        expect(validated).to be_valid
        expect(validated.body).to eq({ 'id' => 42 })
      end
    end

    context 'when response is invalid' do
      let(:response) { Rack::Response.new(JSON.dump({ 'id' => 'foo' }), 200, { 'Content-Type' => 'application/json' }) }

      it 'returns an invalid response' do
        validated = definition.validate_response(request, response)
        expect(validated).not_to be_valid
        expect(validated.body).to eq({ 'id' => 'foo' })
      end

      it 'raises an error with raise_error: true' do
        expect do
          definition.validate_response(request, response, raise_error: true)
        end.to raise_error(OpenapiFirst::ResponseInvalidError)
      end
    end
  end

  describe '#routes' do
    let(:definition) { OpenapiFirst.load('./spec/data/train-travel-api/openapi.yaml') }

    it 'returns routes' do
      routes = definition.routes.map { |route| "#{route.request_method} #{route.path}" }
      expect(routes).to match_array ['GET /stations', 'GET /trips', 'GET /bookings', 'POST /bookings', 'GET /bookings/{bookingId}', 'DELETE /bookings/{bookingId}', 'POST /bookings/{bookingId}/payment']
    end
  end

  describe '#filepath' do
    let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }

    it 'returns the path of the file' do
      expect(definition.filepath).to eq './spec/data/petstore.yaml'
    end

    context 'when initialized with a hash' do
      let(:definition) { OpenapiFirst::Doc.new(YAML.load_file('./spec/data/petstore.yaml')) }

      it 'returns nil' do
        expect(definition.filepath).to be_nil
      end
    end
  end
end
