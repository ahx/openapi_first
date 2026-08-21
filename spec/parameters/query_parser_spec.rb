# frozen_string_literal: true

require 'yaml'

RSpec.describe OpenapiFirst::ParametersParser::Query do
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
  end
end
