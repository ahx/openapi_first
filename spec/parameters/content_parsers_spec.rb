# frozen_string_literal: true

RSpec.describe OpenapiFirst::ParameterContentParsers do
  around do |example|
    original = described_class.parsers.dup
    example.run
    described_class.parsers.replace(original)
  end

  describe '.[]' do
    it 'finds a parser via a regexp matcher' do
      expect(described_class['application/vnd.api+json']).to be_a Proc
    end

    it 'returns nil for an unknown media type' do
      expect(described_class['application/xml']).to be_nil
    end

    it 'returns nil if no media type is given' do
      expect(described_class[nil]).to be_nil
    end
  end

  describe '.register' do
    it 'registers a parser for an exact media type' do
      parser = ->(value) { value.split(',') }
      described_class.register('text/csv', parser)
      expect(described_class['text/csv']).to be parser
      expect(described_class['text/plain']).to be_nil
    end

    it 'replaces a parser that was registered with the same matcher' do
      described_class.register('text/csv', ->(value) { value })
      parser = ->(value) { value.split(',') }
      described_class.register('text/csv', parser)
      expect(described_class['text/csv']).to be parser
    end

    it 'is used to unpack a parameter with that media type' do
      described_class.register('text/csv', ->(value) { value.split(',') })
      parameter = build_parameter(
        { 'in' => 'query', 'name' => 'ids', 'content' => { 'text/csv' => { 'schema' => { 'type' => 'array' } } } }
      )
      expect(unpack(parameter, 'ids' => '1,2')).to eq('ids' => %w[1 2])
    end
  end

  describe 'the built-in JSON parser' do
    let(:parameter) do
      build_parameter(
        { 'in' => 'query', 'name' => 'filter',
          'content' => { 'application/json' => { 'schema' => { 'type' => 'object' } } } }
      )
    end

    it 'parses JSON' do
      expect(unpack(parameter, 'filter' => '{"a":1}')).to eq('filter' => { 'a' => 1 })
    end

    it 'returns the value as is if it is not valid JSON' do
      expect(unpack(parameter, 'filter' => '{')).to eq('filter' => '{')
    end
  end

  def unpack(parameter, values)
    OpenapiFirst::ParametersParser.new([parameter]).unpack(values)
  end
end
