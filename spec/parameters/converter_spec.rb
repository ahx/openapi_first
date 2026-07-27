# frozen_string_literal: true

RSpec.describe OpenapiFirst::Parameters::Converter do
  def convert(value, schema)
    described_class.convert(value, schema)
  end

  shared_examples 'converts primitive types' do |type, valid_input, expected_output, invalid_input = 'invalid'|
    context "with #{type} type" do
      let(:schema) { { 'type' => type } }

      it "converts valid #{type}" do
        expect(convert(valid_input, schema)).to eq(expected_output)
      end

      it "returns original value for invalid #{type}" do
        expect(convert(invalid_input, schema)).to eq(invalid_input)
      end
    end
  end

  shared_examples 'preserves input when no conversion needed' do |input, schema|
    it 'preserves the input' do
      expect(convert(input, schema)).to eq(input)
    end
  end

  it_behaves_like 'preserves input when no conversion needed', '123', nil
  it_behaves_like 'preserves input when no conversion needed', '1', {}
  it_behaves_like 'preserves input when no conversion needed', nil, { 'type' => 'integer' }

  it_behaves_like 'converts primitive types', 'string', '123', '123'
  it_behaves_like 'converts primitive types', 'integer', '123', 123, 'a'
  it_behaves_like 'converts primitive types', 'number', '12.3', 12.3, 'a'

  context 'with integer type' do
    let(:schema) { { 'type' => 'integer' } }

    it 'keeps integer as integer' do
      expect(convert(123, schema)).to eq(123)
    end

    it 'does not convert hex numbers' do
      expect(convert('0x23', schema)).to eq('0x23')
    end
  end

  context 'with boolean type' do
    let(:schema) { { 'type' => 'boolean' } }

    it 'converts "true" to true' do
      expect(convert('true', schema)).to be(true)
    end

    it 'converts "false" to false' do
      expect(convert('false', schema)).to be(false)
    end

    it 'returns original for invalid boolean' do
      expect(convert('wrong', schema)).to eq('wrong')
    end
  end

  it 'ignores format' do
    schema = { 'type' => 'string', 'format' => 'date' }
    expect(convert('2020-09-15', schema)).to eq('2020-09-15')
  end

  context 'with object schemas' do
    let(:simple_object_schema) do
      {
        'type' => 'object',
        'properties' => {
          'id' => { 'type' => 'integer' }
        }
      }
    end

    let(:nested_object_schema) do
      {
        'type' => 'object',
        'properties' => {
          'data' => {
            'type' => 'object',
            'properties' => {
              'id' => { 'type' => 'integer' }
            }
          }
        }
      }
    end

    it 'converts object properties' do
      input = { 'id' => '123' }
      expect(convert(input, simple_object_schema)).to eq({ 'id' => 123 })
    end

    it 'converts nested objects' do
      input = { 'data' => { 'id' => '123' } }
      expected = { 'data' => { 'id' => 123 } }
      expect(convert(input, nested_object_schema)).to eq(expected)
    end

    it 'converts when schema has properties but no type' do
      schema = { 'properties' => { 'id' => { 'type' => 'integer' } } }
      input = { 'id' => '123' }
      expect(convert(input, schema)).to eq({ 'id' => 123 })
    end

    it 'ignores unknown properties' do
      input = { 'id' => '123', 'unknown' => 'value' }
      expected = { 'id' => 123, 'unknown' => 'value' }
      expect(convert(input, simple_object_schema)).to eq(expected)
    end

    it 'does not convert string to object' do
      expect(convert('foo', simple_object_schema)).to eq('foo')
    end
  end

  context 'with array schemas' do
    let(:simple_array_schema) { { 'type' => 'array', 'items' => { 'type' => 'integer' } } }
    let(:prefix_items_schema) do
      {
        'type' => 'array',
        'prefixItems' => [{ 'type' => 'string' }, { 'type' => 'integer' }]
      }
    end

    it 'converts array items' do
      expect(convert(%w[1 2 3], simple_array_schema)).to eq([1, 2, 3])
    end

    it 'converts with prefixItems' do
      expect(convert(%w[1 2], prefix_items_schema)).to eq(['1', 2])
    end

    it 'handles prefixItems with additional items' do
      schema = { 'type' => 'array', 'prefixItems' => [{ 'type' => 'integer' }] }
      expect(convert(%w[1 2 3], schema)).to eq([1, '2', '3'])
    end

    it 'handles prefixItems with items schema' do
      schema = {
        'type' => 'array',
        'prefixItems' => [{ 'type' => 'integer' }, { 'type' => 'string' }],
        'items' => { 'type' => 'integer' }
      }
      expect(convert(%w[1 a 3 4], schema)).to eq([1, 'a', 3, 4])
    end

    it 'converts nested arrays' do
      schema = {
        'type' => 'array',
        'items' => {
          'type' => 'array',
          'items' => { 'type' => 'integer' }
        }
      }
      expect(convert([%w[1 2], %w[3 4]], schema)).to eq([[1, 2], [3, 4]])
    end

    it 'does not convert string to array' do
      expect(convert('foo', simple_array_schema)).to eq('foo')
    end
  end

  it 'converts complex nested structures' do
    schema = {
      'type' => 'object',
      'properties' => {
        'data' => {
          'type' => 'array',
          'items' => {
            'type' => 'object',
            'properties' => {
              'id' => { 'type' => 'integer' },
              'clientIds' => {
                'type' => 'array',
                'items' => { 'type' => 'integer' }
              }
            }
          }
        }
      }
    }
    input = { 'data' => [{ 'id' => '1', 'clientIds' => %w[1 2] }] }
    expected = { 'data' => [{ 'id' => 1, 'clientIds' => [1, 2] }] }
    expect(convert(input, schema)).to eq(expected)
  end

  context 'with composition schemas' do
    shared_examples 'composition schema conversion' do |composition_key|
      it "converts properties from #{composition_key} branches" do
        schema = {
          composition_key => [
            {
              'type' => 'object',
              'properties' => { 'name' => { 'type' => 'string' } }
            },
            {
              'type' => 'object',
              'properties' => { 'age' => { 'type' => 'integer' } }
            }
          ]
        }
        input = { 'name' => 'John', 'age' => '25' }
        expect(convert(input, schema)).to eq({ 'name' => 'John', 'age' => 25 })
      end
    end

    it_behaves_like 'composition schema conversion', 'oneOf'
    it_behaves_like 'composition schema conversion', 'allOf'
    it_behaves_like 'composition schema conversion', 'anyOf'

    context 'with oneOf' do
      it 'handles overlapping properties' do
        schema = {
          'oneOf' => [
            {
              'type' => 'object',
              'properties' => {
                'id' => { 'type' => 'string' },
                'value' => { 'type' => 'integer' }
              }
            },
            {
              'type' => 'object',
              'properties' => {
                'id' => { 'type' => 'string' },
                'count' => { 'type' => 'integer' }
              }
            }
          ]
        }
        input = { 'id' => 'test', 'value' => '42', 'count' => '10' }
        expect(convert(input, schema)).to eq({ 'id' => 'test', 'value' => 42, 'count' => 10 })
      end

      it 'ignores undefined properties' do
        schema = {
          'oneOf' => [
            { 'type' => 'object', 'properties' => { 'name' => { 'type' => 'string' } } }
          ]
        }
        input = { 'name' => 'John', 'unknown' => 'value' }
        expect(convert(input, schema)).to eq({ 'name' => 'John', 'unknown' => 'value' })
      end
    end

    context 'with allOf and nested objects' do
      it 'handles complex nested schemas' do
        schema = {
          'allOf' => [
            {
              'type' => 'object',
              'properties' => {
                'user' => {
                  'type' => 'object',
                  'properties' => { 'id' => { 'type' => 'integer' } }
                }
              }
            },
            {
              'type' => 'object',
              'properties' => {
                'metadata' => {
                  'type' => 'object',
                  'properties' => { 'created' => { 'type' => 'string' } }
                }
              }
            }
          ]
        }
        input = { 'user' => { 'id' => '123' }, 'metadata' => { 'created' => '2023-01-01' } }
        expected = { 'user' => { 'id' => 123 }, 'metadata' => { 'created' => '2023-01-01' } }
        expect(convert(input, schema)).to eq(expected)
      end
    end

    context 'with mixed schemas' do
      it 'combines direct properties with composition' do
        schema = {
          'properties' => { 'id' => { 'type' => 'string' } },
          'oneOf' => [
            { 'type' => 'object', 'properties' => { 'value' => { 'type' => 'integer' } } }
          ]
        }
        input = { 'id' => 'test', 'value' => '123' }
        expect(convert(input, schema)).to eq({ 'id' => 'test', 'value' => 123 })
      end

      it 'handles empty composition arrays' do
        schema = { 'oneOf' => [] }
        input = { 'name' => 'test' }
        expect(convert(input, schema)).to eq({ 'name' => 'test' })
      end

      it 'handles composition with missing properties' do
        schema = {
          'oneOf' => [
            { 'type' => 'object' },
            { 'type' => 'object', 'properties' => { 'name' => { 'type' => 'string' } } }
          ]
        }
        input = { 'name' => 'test', 'other' => 'value' }
        expect(convert(input, schema)).to eq({ 'name' => 'test', 'other' => 'value' })
      end
    end
  end
end
