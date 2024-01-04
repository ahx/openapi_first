# frozen_string_literal: true

RSpec.describe OpenapiFirst::RuntimeRequest do
  subject(:request) do
    definition.request(rack_request)
  end

  let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }

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

  describe '#known_path?' do
    context 'with known path' do
      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/pets'))
      end

      it 'returns true' do
        expect(request).to be_known_path
      end
    end

    context 'with unknown path' do
      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/unknown'))
      end

      it 'returns false' do
        expect(request).not_to be_known_path
      end
    end
  end

  describe '#known_request_method?' do
    context 'with known request method' do
      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/pets'))
      end

      it 'returns true' do
        expect(request).to be_known_request_method
      end
    end

    context 'with unknown request method' do
      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/pets', method: 'PATCH'))
      end

      it 'returns false' do
        expect(request).not_to be_known_request_method
      end
    end

    context 'with known request method, but unknown path' do
      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/unknown'))
      end

      it 'returns false' do
        expect(request).not_to be_known_request_method
      end
    end
  end

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

  describe '#path_params' do
    let(:definition) { OpenapiFirst.load('./spec/data/parameters.yaml') }

    let(:rack_request) do
      Rack::Request.new(Rack::MockRequest.env_for('/stuff/42'))
    end

    it 'returns the path param' do
      expect(subject.path_params['id']).to eq(42)
    end

    context 'without defined parameters' do
      let(:rack_request) do
        Rack::Request.new(Rack::MockRequest.env_for('/search'))
      end

      it 'returns an empty Hash' do
        expect(subject.path_params).to eq({})
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
  end
end
