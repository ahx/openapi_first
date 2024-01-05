# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OpenapiFirst::Definition do
  def build_request(path, method: 'GET')
    Rack::Request.new(Rack::MockRequest.env_for(path, method:))
  end

  describe '#request' do
    context 'with a matching path and request method' do
      let(:definition) { OpenapiFirst.load('./spec/data/incompatible-routes.yaml') }
      let(:request) { Rack::Request.new(Rack::MockRequest.env_for('/foo/1')) }

      it 'returns a Definition::RuntimeRequest' do
        expect(definition.request(request)).to be_a(OpenapiFirst::RuntimeRequest)
      end

      it 'is a known request' do
        expect(definition.request(request)).to be_known
      end
    end

    context 'with different variables in common nested routes' do
      let(:definition) { OpenapiFirst.load('./spec/data/incompatible-routes.yaml') }

      it 'finds a match' do
        request = definition.request(build_request('/foo/1'))
        expect(request.path_params).to eq({ 'fooId' => '1' })

        request = definition.request(build_request('/foo/1/bar'))
        expect(request.path_params).to eq({ 'id' => '1' })

        request = definition.request(build_request('/foo/special'))
        expect(request.path_params).to eq({})
      end
    end

    context 'with different patterns on the same path' do
      let(:definition) { OpenapiFirst.load('./spec/data/parameters-path.yaml') }

      it 'supports /{date}' do
        runtime_request = definition.request(build_request('/info/2020-01-01'))
        operation_id = runtime_request.operation_id

        expect(operation_id).to eq 'info_date'
        expect(runtime_request.params['date']).to eq('2020-01-01')
      end

      pending 'supports /{start_date}..{end_date}' do
        runtime_request = definition.request(build_request('/info/2020-01-01..2020-01-02'))
        operation_id = runtime_request.operation_id
        expect(operation_id).to eq 'info_date_range'

        expect(runtime_request.params['start_date']).to eq('2020-01-01')
        expect(runtime_request.params['end_date']).to eq('2020-01-02')
      end

      it 'still works without parameters' do
        runtime_request = definition.request(build_request('/info'))
        operation_id = runtime_request.operation_id
        expect(operation_id).to eq 'info'
        expect(runtime_request.params).to be_empty
      end
    end

    context 'with a matching path but unknown request method' do
      let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }
      let(:rack_request) { build_request('/pets', method: 'PATCH') }

      it 'has a known path' do
        expect(definition.request(rack_request)).to be_known_path
      end

      it 'has no known request method' do
        expect(definition.request(rack_request)).not_to be_known_request_method
      end
    end

    context 'with SCRIPT_NAME' do
      let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }
      let(:rack_request) { Rack::Request.new(Rack::MockRequest.env_for('/42', script_name: '/pets')) }

      it 'respects SCRIPT_NAME to build the whole path' do
        expect(definition.request(rack_request)).to be_known_path
        expect(definition.request(rack_request).operation_id).to eq('showPetById')
      end
    end
  end

  describe '#response' do
    let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }
    let(:request) { build_request('/pets') }
    let(:response) { Rack::Response.new('', 200, { 'Content-Type' => 'application/json' }) }

    it 'returns a Definition::RuntimeResponse' do
      result = definition.response(request, response)
      expect(result).to be_a(OpenapiFirst::RuntimeResponse)
      expect(result.description).to eq('A paged array of pets')
    end
  end

  describe '#operations' do
    let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }

    it 'returns a list of operations' do
      expect(definition.operations.length).to eq 3
      expected_ids = %w[listPets createPets showPetById]
      expect(definition.operations.map(&:operation_id)).to eq expected_ids
    end
  end

  describe '#path' do
    let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }

    it 'finds a path item' do
      path = definition.path('/pets')
      expect(path.path).to eq '/pets'
      expect(path).to be_a(OpenapiFirst::Definition::PathItem)
    end

    it 'returns nil if path is unknown' do
      path = definition.path('/fats')
      expect(path).to be_nil
    end

    it 'does not evaluate URI templates' do
      path = definition.path('/pets/1')
      expect(path).to be_nil
    end
  end

  describe '#filepath' do
    let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }

    it 'returns the path of the file' do
      expect(definition.filepath).to eq './spec/data/petstore.yaml'
    end
  end
end
