# frozen_string_literal: true

require 'yaml'

RSpec.describe OpenapiFirst::QueryStringParser do
  def parser_for(definitions)
    definitions = [definitions] unless definitions.is_a?(Array)
    described_class.new(build_parameters(definitions))
  end

  describe '#unpack' do
    tests = YAML.load_file(File.expand_path('./query-parameter-tests.yaml', __dir__))

    tests.each do |test|
      description = test['description']
      next unless test['unpacked_value']

      it description do
        parameter, query_string, unpacked_value = test.values_at('parameter', 'query_string', 'unpacked_value')
        expect(parser_for(parameter).unpack(query_string)).to eq(unpacked_value)
      end
    end

    context 'with invalid query string encoding' do
      it 'raises an exception' do
        parser = parser_for({ 'in' => 'query', 'name' => 'limit' })
        expect do
          parser.unpack('limit=%E0%A4%A')
        end.to raise_error(Rack::Utils::InvalidParameterError, 'invalid %-encoding (%E0%A4%A)')
      end
    end

    context 'with more parameters than Rack accepts' do
      it 'raises an exception' do
        parser = parser_for({ 'in' => 'query', 'name' => 'limit' })
        query_string = Array.new(4097) { "x#{_1}=1" }.join('&')
        expect do
          parser.unpack(query_string)
        end.to raise_error(Rack::Utils::InvalidParameterError)
      end
    end

    context 'with a value that is not valid UTF-8' do
      let(:deep_object) do
        { 'in' => 'query', 'name' => 'filter', 'style' => 'deepObject', 'explode' => true,
          'schema' => { 'type' => 'object' } }
      end

      it 'raises an exception for a defined parameter' do
        parser = parser_for({ 'in' => 'query', 'name' => 'limit' })
        expect do
          parser.unpack('limit=%C3')
        end.to raise_error(Rack::Utils::InvalidParameterError, 'invalid encoding (%C3)')
      end

      it 'raises an exception for a repeated defined parameter' do
        parser = parser_for({ 'in' => 'query', 'name' => 'limit' })
        expect do
          parser.unpack('limit=1&limit=%C3')
        end.to raise_error(Rack::Utils::InvalidParameterError)
      end

      it 'raises an exception for a deepObject parameter sent without properties' do
        expect do
          parser_for(deep_object).unpack('filter=%C3')
        end.to raise_error(Rack::Utils::InvalidParameterError)
      end

      it 'raises an exception for a deepObject property name' do
        expect do
          parser_for(deep_object).unpack('filter[%C3]=x')
        end.to raise_error(Rack::Utils::InvalidParameterError)
      end

      it 'raises an exception for a deepObject property value' do
        expect do
          parser_for(deep_object).unpack('filter[name]=%C3')
        end.to raise_error(Rack::Utils::InvalidParameterError)
      end

      it 'raises an exception for an undefined parameter' do
        parser = parser_for([{ 'in' => 'query', 'name' => 'limit' }, deep_object])
        expect do
          parser.unpack('limit=1&other=%C3')
        end.to raise_error(Rack::Utils::InvalidParameterError)
      end

      it 'raises an exception for an undefined parameter name' do
        parser = parser_for([{ 'in' => 'query', 'name' => 'limit' }, deep_object])
        expect do
          parser.unpack('limit=1&%C3=x')
        end.to raise_error(Rack::Utils::InvalidParameterError)
      end

      it 'accepts a parameter without a value' do
        parser = parser_for({ 'in' => 'query', 'name' => 'limit' })
        expect(parser.unpack('limit')).to eq('limit' => nil)
      end
    end
  end

  describe '#unknown_values' do
    tests = YAML.load_file(File.expand_path('./query-parameter-tests.yaml', __dir__))

    tests.each do |test|
      next unless test.key?('unknown_values')

      it test['description'] do
        parameter, query_string, unknown_values = test.values_at('parameter', 'query_string', 'unknown_values')
        expect(parser_for(parameter).unknown_values(query_string)).to eq(unknown_values)
      end
    end

    it 'returns nil if the query string cannot be decoded' do
      parser = parser_for({ 'in' => 'query', 'name' => 'limit' })
      expect(parser.unknown_values('limit=1&unknown=%C3')).to be_nil
    end
  end
end
