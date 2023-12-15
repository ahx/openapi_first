# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OpenapiFirst::Definition do
  def build_request(path, method: 'GET')
    Rack::Request.new(Rack::MockRequest.env_for(path, method:))
  end

  describe '#request' do
    let(:result) { definition.request(request) }

    context 'with a matching path and operation' do
      let(:definition) { OpenapiFirst.load('./spec/data/incompatible-routes.yaml') }
      let(:request) { Rack::Request.new(Rack::MockRequest.env_for('/foo/1')) }

      it 'returns a Definition::RuntimeRequest' do
        expect(result).to be_a(OpenapiFirst::Definition::RuntimeRequest)
        expect(result.operation.operation_id).to eq 'foo'
      end

      it 'has a path_item' do
        expect(result.path_item).to be_a(OpenapiFirst::Definition::PathItem)
        expect(result.path_item.path).to eq('/foo/{fooId}')
      end
    end

    context 'with different variables in common nested routes' do
      let(:definition) { OpenapiFirst.load('./spec/data/incompatible-routes.yaml') }

      specify do
        match = definition.request(build_request('/foo/1'))
        expect(match.path_params).to eq({ 'fooId' => '1' })
        expect(match.path_item.path).to eq('/foo/{fooId}')

        match = definition.request(build_request('/foo/1/bar'))
        expect(match.path_params).to eq({ 'id' => '1' })
        expect(match.path_item.path).to eq('/foo/{id}/bar')

        match = definition.request(build_request('/foo/special'))
        expect(match.path_params).to eq({})
        expect(match.path_item.path).to eq('/foo/special')
      end
    end

    context 'with a matching path but unknown request method' do
      let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }
      let(:request) { build_request('/pets', method: 'PATCH') }

      it 'has a path_item' do
        expect(result.path_item).to be_a(OpenapiFirst::Definition::PathItem)
      end

      it 'has no operation' do
        expect(result.operation).to be_nil
      end
    end
  end

  describe '#response' do
    let(:definition) { OpenapiFirst.load('./spec/data/petstore.yaml') }
    let(:request) { build_request('/pets') }
    let(:response) { Rack::Response.new('', 200, { 'Content-Type' => 'application/json' }) }

    it 'returns a Definition::RuntimeResponse' do
      result = definition.response(request, response)
      expect(result).to be_a(OpenapiFirst::Definition::RuntimeResponse)
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
