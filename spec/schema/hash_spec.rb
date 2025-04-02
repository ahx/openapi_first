# frozen_string_literal: true

RSpec.describe OpenapiFirst::Schema::Hash do
  it 'validates all schemas' do
    a_schema = JSONSchemer.schema({ 'type' => 'integer' })
    b_schema = JSONSchemer.schema({ 'type' => 'string' })

    schema_hash = described_class.new({ 'a' => a_schema, 'b' => b_schema })
    errors = schema_hash.validate('a' => 'a', 'b' => 1).errors

    expect(errors.size).to eq(2)
    expect(errors[0]).to have_attributes(
      message: 'value at `/a` is not an integer',
      data_pointer: '/a',
      schema_pointer: '',
      schema: { 'type' => 'integer' },
      type: 'integer',
      details: nil
    )
    expect(errors[1]).to have_attributes(
      message: 'value at `/b` is not a string',
      data_pointer: '/b',
      schema_pointer: '',
      schema: { 'type' => 'string' },
      type: 'string',
      details: nil
    )
  end
end
