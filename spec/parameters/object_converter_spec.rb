# frozen_string_literal: true

RSpec.describe OpenapiFirst::Parameter::Converter::ObjectConverter do
  describe '.get_properties' do
    it 'returns properties for a simple object' do
      schema = {
        'type' => 'object',
        'properties' => {
          'name' => { 'type' => 'string' },
          'age' => { 'type' => 'integer' }
        }
      }
      properties = described_class.get_properties(schema)
      expect(properties).to eq(
        'name' => { 'type' => 'string' },
        'age' => { 'type' => 'integer' }
      )
    end

    it 'handles additionalProperties with an object' do
      schema = {
        'type' => 'object',
        'additionalProperties' => {
          'color' => { 'type' => 'string' }
        },
        'properties' => {
          'name' => { 'type' => 'string' }
        }
      }
      properties = described_class.get_properties(schema)
      expect(properties).to eq(
        'name' => { 'type' => 'string' },
        'color' => { 'type' => 'string' }
      )
    end

    it 'handles additionalProperties: false' do
      schema = {
        'type' => 'object',
        'additionalProperties' => false,
        'properties' => {
          'name' => { 'type' => 'string' }
        }
      }
      properties = described_class.get_properties(schema)
      expect(properties).to eq(
        'name' => { 'type' => 'string' }
      )
    end

    it 'handles properties defined in then/else' do
      schema = {
        'type' => 'object',
        'if' => { 'properties' => { 'weekday' => { 'const' => 'Monday' } } },
        'then' => { 'properties' => { 'topping' => { 'type' => 'string' } } },
        'else' => { 'properties' => { 'side' => { 'type' => 'string' } } }
      }
      properties = described_class.get_properties(schema)
      expect(properties).to eq(
        'topping' => { 'type' => 'string' },
        'side' => { 'type' => 'string' }
      )
    end

    it 'returns nil for a schema without properties' do
      expect(described_class.get_properties({ 'type' => 'object' })).to be_nil
    end

    it 'returns nil for an empty schema' do
      expect(described_class.get_properties({})).to be_nil
    end

    it 'returns nil if no schema is given' do
      expect(described_class.get_properties(nil)).to be_nil
    end

    it 'handles if-then-else' do
      schema = {
        'type' => 'object',
        'properties' => {
          'customer_name' => {
            'type' => 'string'
          },
          'weekday' => {
            'default' => 'Tuesday',
            'enum' => %w[
              Monday
              Tuesday
            ]
          }
        },
        'if' => {
          'properties' => {
            'weekday' => {
              'const' => 'Monday'
            }
          }
        },
        'then' => {
          'additionalProperties' => {
            'topping' => {
              'type' => 'string'
            }
          }
        },
        'else' => {
          'additionalProperties' => false
        }
      }

      properties = described_class.get_properties(schema)
      expect(properties).to eq(
        'customer_name' => {
          'type' => 'string'
        },
        'weekday' => {
          'default' => 'Tuesday',
          'enum' => %w[
            Monday
            Tuesday
          ]
        },
        'topping' => {
          'type' => 'string'
        }
      )
    end
  end
end
