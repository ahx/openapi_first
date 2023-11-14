# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OpenapiFirst::Definition do
  describe '#find_path_item_and_params' do
    let(:definition) { OpenapiFirst.load('./spec/data/incompatible-routes.yaml') }

    it 'works with with different variables in common nested routes' do
      path_item, path_params = definition.find_path_item_and_params('/foo/1')
      expect(path_params).to eq({ 'fooId' => '1' })
      expect(path_item.path).to eq('/foo/{fooId}')

      path_item, path_params = definition.find_path_item_and_params('/foo/1/bar')
      expect(path_params).to eq({ 'id' => '1' })
      expect(path_item.path).to eq('/foo/{id}/bar')

      path_item, path_params = definition.find_path_item_and_params('/foo/special')
      expect(path_params).to eq({})
      expect(path_item.path).to eq('/foo/special')
    end

    it 'finds a PathItem' do
      path_item, _path_params = definition.find_path_item_and_params('/foo/1')
      expect(path_item.find_operation('get').operation_id).to eq('foo')
    end
  end

  describe '#operations' do
    it 'returns a list of operations' do
      definition = OpenapiFirst.load('./spec/data/petstore.yaml')
      expect(definition.operations.length).to eq 3
      expected_ids = %w[listPets createPets showPetById]
      expect(definition.operations.map(&:operation_id)).to eq expected_ids
    end
  end

  describe '#filepath' do
    it 'returns the path of the file' do
      definition = OpenapiFirst.load('./spec/data/petstore.yaml')
      expect(definition.filepath).to eq './spec/data/petstore.yaml'
    end
  end
end
