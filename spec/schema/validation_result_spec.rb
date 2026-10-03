# frozen_string_literal: true

RSpec.describe OpenapiFirst::Schema::ValidationResult do
  def schema(hash)
    JSONSchemer.schema(hash)
  end

  describe 'missing required field' do
    specify do
      validation = schema({ required: ['id'] }).validate({})
      expect(described_class.new(validation).errors.first.message).to eq 'object at root is missing required properties: id'
    end
  end

  describe 'missing dependentRequired field' do
    specify do
      validation = schema({ 'dependentRequired' => { 'id' => ['type'] } }).validate({ 'id' => '2' })
      expect(described_class.new(validation).errors.first.message).to eq 'object at `/id` is missing required properties'
    end
  end
end
