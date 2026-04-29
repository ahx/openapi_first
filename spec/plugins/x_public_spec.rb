# frozen_string_literal: true

RSpec.describe 'OpenapiFirst::Plugins::XPublic' do
  def build_request(path, method: 'GET')
    Rack::Request.new(Rack::MockRequest.env_for(path, method:))
  end

  let(:spec) do
    {
      'openapi' => '3.1.0',
      'info' => { 'title' => 'Test', 'version' => '1' },
      'paths' => {
        '/public' => {
          'get' => {
            'x-public' => true,
            'responses' => { '200' => { 'description' => 'ok' } }
          }
        },
        '/private' => {
          'get' => {
            'responses' => { '200' => { 'description' => 'ok' } }
          }
        }
      }
    }
  end

  context 'with default field (x-public)' do
    let(:definition) do
      OpenapiFirst.parse(spec) { |c| c.plugin :x_public }
    end

    it 'passes requests to operations with x-public' do
      validated = definition.validate_request(build_request('/public'))
      expect(validated).to be_valid
    end

    it 'returns not_found for operations without x-public' do
      validated = definition.validate_request(build_request('/private'))
      expect(validated).to be_invalid
      expect(validated.error.type).to eq(:not_found)
    end

    it 'does not affect unknown routes (already not_found)' do
      validated = definition.validate_request(build_request('/unknown'))
      expect(validated).to be_invalid
      expect(validated.error.type).to eq(:not_found)
    end
  end

  context 'with custom field name' do
    let(:definition) do
      spec['paths']['/public']['get']['x-visible'] = true
      spec['paths']['/public']['get'].delete('x-public')
      OpenapiFirst.parse(spec) { |c| c.plugin :x_public, field: 'x-visible' }
    end

    it 'passes requests when the custom field is present' do
      validated = definition.validate_request(build_request('/public'))
      expect(validated).to be_valid
    end

    it 'returns not_found when the custom field is absent' do
      validated = definition.validate_request(build_request('/private'))
      expect(validated).to be_invalid
      expect(validated.error.type).to eq(:not_found)
    end
  end

  context 'with if: condition' do
    let(:definition) do
      OpenapiFirst.parse(spec) do |c|
        c.plugin :x_public, if: ->(req) { req.host == 'api.example.com' }
      end
    end

    it 'applies the check when the condition matches' do
      request = Rack::Request.new(
        Rack::MockRequest.env_for('http://api.example.com/private', method: 'GET')
      )
      validated = definition.validate_request(request)
      expect(validated).to be_invalid
      expect(validated.error.type).to eq(:not_found)
    end

    it 'skips the check when the condition does not match' do
      request = Rack::Request.new(
        Rack::MockRequest.env_for('http://other.example.com/private', method: 'GET')
      )
      validated = definition.validate_request(request)
      expect(validated).to be_valid
    end
  end
end
