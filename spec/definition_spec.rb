# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OpenapiFirst::Definition do
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
