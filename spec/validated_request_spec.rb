# frozen_string_literal: true

RSpec.describe OpenapiFirst::ValidatedRequest do
  subject(:request) do
    definition.validate_request(rack_request)
  end

  let(:rack_request) do
    Rack::Request.new(Rack::MockRequest.env_for('/pets/42'))
  end

  let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }

  describe '#valid?' do
    context 'with valid request' do
      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/pets', method: 'POST', input: '{}'))
      end

      it 'returns true' do
        expect(request).to be_valid
      end
    end

    context 'with invalid request' do
      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/pets/23', method: 'POST', input: '[]'))
      end

      it 'returns false' do
        expect(request).not_to be_valid
      end
    end
  end

  describe '#known?' do
    context 'with known path and request method' do
      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/pets'))
      end

      it 'returns true' do
        expect(request).to be_known
      end
    end

    context 'with known path, but unknown request method' do
      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/pets', method: 'PATCH'))
      end

      it 'returns false' do
        expect(request).not_to be_known
      end
    end

    context 'with unknown path' do
      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/unknown'))
      end

      it 'returns false' do
        expect(request).not_to be_known
      end
    end
  end

  # describe '#known_path?' do
  #   context 'with known path' do
  #     let(:rack_request) do
  #       Rack::Request.new(Rack::MockRequest.env_for('/pets'))
  #     end

  #     it 'returns true' do
  #       expect(request).to be_known_path
  #     end
  #   end

  #   context 'with unknown path' do
  #     let(:rack_request) do
  #       Rack::Request.new(Rack::MockRequest.env_for('/unknown'))
  #     end

  #     it 'returns false' do
  #       expect(request).not_to be_known_path
  #     end
  #   end
  # end

  # describe '#known_request_method?' do
  #   context 'with known request method' do
  #     let(:rack_request) do
  #       Rack::Request.new(Rack::MockRequest.env_for('/pets'))
  #     end

  #     it 'returns true' do
  #       expect(request).to be_known_request_method
  #     end
  #   end

  #   context 'with unknown request method' do
  #     let(:rack_request) do
  #       Rack::Request.new(Rack::MockRequest.env_for('/pets', method: 'PATCH'))
  #     end

  #     it 'returns false' do
  #       expect(request).not_to be_known_request_method
  #     end
  #   end

  #   context 'with known request method, but unknown path' do
  #     let(:rack_request) do
  #       Rack::Request.new(Rack::MockRequest.env_for('/unknown'))
  #     end

  #     it 'returns false' do
  #       expect(request).not_to be_known_request_method
  #     end
  #   end
  # end

  describe '#operation_id' do
    let(:rack_request) do
      Rack::Request.new(Rack::MockRequest.env_for('/pets'))
    end

    it 'returns the operation ID' do
      expect(request.operation_id).to eq('listPets')
    end
  end

  describe '#content_type' do
    let(:definition) { OpenapiFirst.load('./spec/data/petstore-expanded.yaml') }

    let(:rack_request) do
      Rack::Request.new(Rack::MockRequest.env_for('/pets', method: 'POST')).tap do |r|
        r.add_header 'CONTENT_TYPE', 'application/json; charset=UTF8'
      end
    end

    it 'returns the content type of the original request' do
      expect(request.content_type).to eq('application/json; charset=UTF8')
    end
  end

  describe '#media_type' do
    let(:definition) { OpenapiFirst.load('./spec/data/petstore-expanded.yaml') }

    let(:rack_request) do
      Rack::Request.new(Rack::MockRequest.env_for('/pets', method: 'POST')).tap do |r|
        r.add_header 'CONTENT_TYPE', 'application/json; charset=UTF8'
      end
    end

    it 'returns the content type without parameters' do
      expect(request.media_type).to eq('application/json')
    end
  end

  describe '#params' do
    let(:definition) { OpenapiFirst.load('./spec/data/parameters.yaml') }

    let(:rack_request) do
      Rack::Request.new(Rack::MockRequest.env_for('/stuff/42?version=2'))
    end

    it 'returns path and query params' do
      expect(subject.params['id']).to eq(42)
      expect(subject.params['version']).to eq(2)
    end
  end

  describe '#path_parameters' do
    let(:definition) { OpenapiFirst.load('./spec/data/parameters.yaml') }

    let(:rack_request) do
      Rack::Request.new(Rack::MockRequest.env_for('/stuff/42'))
    end

    it 'returns the path param' do
      expect(subject.path_parameters['id']).to eq(42)
    end

    context 'without defined parameters' do
      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/search'))
      end

      it 'returns an empty Hash' do
        expect(subject.path_parameters).to eq({})
      end
    end

    context 'with kebab-case path params' do
      let(:definition) do
        OpenapiFirst.parse({
                             'openapi' => '3.1.0',
                             'paths' => {
                               '/ke-bab/{ke-bab}/{under_score}' => {
                                 'get' => {
                                   'parameters' => [
                                     {
                                       'name' => 'ke-bab',
                                       'in' => 'path',
                                       'required' => true,
                                       'schema' => {
                                         'type' => 'string'
                                       }
                                     }, {
                                       'name' => 'under_score',
                                       'in' => 'path',
                                       'required' => true,
                                       'schema' => {
                                         'type' => 'string'
                                       }
                                     }
                                   ]
                                 }
                               }
                             }
                           })
      end

      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/ke-bab/one/two'))
      end

      it 'parses path parameters' do
        expect(subject.path_parameters['ke-bab']).to eq('one')
        expect(subject.path_parameters['under_score']).to eq('two')
      end
    end
  end

  describe '#query' do
    let(:rack_request) do
      Rack::Request.new(Rack::MockRequest.env_for('/pets?limit=3&unknown=5'))
    end

    it 'returns defined params' do
      expect(subject.query['limit']).to eq(3)
    end

    it 'does not include unknown params' do
      expect(subject.query['unknown']).to be_nil
    end

    context 'without defined parameters' do
      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/pets/42'))
      end

      it 'returns an empty Hash' do
        expect(subject.query).to eq({})
      end
    end

    it 'aliases to query_parameters' do
      expect(subject.query_parameters['limit']).to eq(3)
    end
  end

  describe '#headers' do
    let(:definition) { OpenapiFirst.load('./spec/data/parameters.yaml') }

    let(:rack_request) do
      env = Rack::MockRequest.env_for('/search')
      env['HTTP_HEADER'] = 'something'
      env['HTTP_UNKNOWN'] = '5'
      Rack::Request.new(env)
    end

    it 'returns defined params' do
      expect(subject.headers['header']).to eq('something')
    end

    it 'does not include unknown params' do
      expect(subject.headers['unknown']).to be_nil
    end

    context 'without defined parameters' do
      let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }

      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/pets'))
      end

      it 'returns an empty Hash' do
        expect(subject.headers).to eq({})
      end
    end
  end

  describe '#cookies' do
    let(:definition) { OpenapiFirst.load('./spec/data/cookie-parameter-validation.yaml') }

    let(:rack_request) do
      env = Rack::MockRequest.env_for('/')
      env['HTTP_COOKIE'] = 'knusper=42'
      Rack::Request.new(env)
    end

    it 'returns defined params' do
      expect(subject.cookies['knusper']).to eq(42)
    end

    context 'without defined parameters' do
      let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }

      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/pets'))
      end

      it 'returns an empty Hash' do
        expect(subject.cookies).to eq({})
      end
    end
  end

  describe '#body' do
    let(:definition) { OpenapiFirst.load('./spec/data/petstore-expanded.yaml') }

    let(:rack_request) do
      env = Rack::MockRequest.env_for('/pets', method: 'POST', input: JSON.dump(foo: 'bar'))
      env['CONTENT_TYPE'] = 'application/json'
      Rack::Request.new(env)
    end

    it 'returns the parsed body' do
      expect(subject.body).to eq('foo' => 'bar')
    end

    context 'with invalid JSON' do
      let(:rack_request) do
        env = Rack::MockRequest.env_for('/pets', method: 'POST', input: '{foobar}')
        env['CONTENT_TYPE'] = 'application/json'
        Rack::Request.new(env)
      end

      it 'raises a ParseError' do
        expect { subject.body }.to raise_error(OpenapiFirst::ParseError, 'Failed to parse body as JSON')
      end
    end

    it 'is aliased with parsed_body' do
      expect(subject.parsed_body).to eq('foo' => 'bar')
    end
  end

  describe '#path' do
    it 'returns the path of the request' do
      expect(subject.path).to eq('/pets/42')
    end
  end

  describe '#path_item' do
    it 'returns the path item definition for the request' do
      expect(subject.path_item.path).to eq('/pets/{petId}')
    end
  end

  # describe '#path_definition' do
  #   it 'returns the path item definition for the request' do
  #     expect(subject.path_definition).to eq('/pets/{petId}')
  #   end
  # end

  describe '#request_method' do
    it 'returns the request_method of the request' do
      expect(subject.request_method).to eq('get')
    end
  end

  describe '#operation' do
    it 'returns the request operation' do
      expect(request.operation.path).to eq('/pets/{petId}')
    end
  end
end
