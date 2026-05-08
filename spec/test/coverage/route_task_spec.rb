# frozen_string_literal: true

RSpec.describe OpenapiFirst::Test::Coverage::RouteTask do
  let(:spec_with_summary) do
    {
      'openapi' => '3.1.0',
      'paths' => {
        '/pets' => {
          'get' => {
            'summary' => 'List all pets',
            'description' => 'Returns every pet in the store.',
            'responses' => { '200' => { 'description' => 'ok' } }
          }
        }
      }
    }
  end

  let(:spec_with_only_description) do
    spec = spec_with_summary.dup
    spec['paths']['/pets']['get'] = spec_with_summary['paths']['/pets']['get'].except('summary')
    spec
  end

  let(:spec_without_either) do
    {
      'openapi' => '3.1.0',
      'paths' => {
        '/pets' => {
          'get' => { 'responses' => { '200' => { 'description' => 'ok' } } }
        }
      }
    }
  end

  def first_route(spec)
    OpenapiFirst::Test::Coverage::Plan.for(OpenapiFirst.parse(spec, filepath: 'x.yaml')).routes.first
  end

  describe '#summary' do
    it 'returns the operation summary when present' do
      expect(first_route(spec_with_summary).summary).to eq('List all pets')
    end

    it 'falls back to description when summary is absent' do
      expect(first_route(spec_with_only_description).summary).to eq('Returns every pet in the store.')
    end

    it 'returns nil when neither is present' do
      expect(first_route(spec_without_either).summary).to be_nil
    end
  end
end
