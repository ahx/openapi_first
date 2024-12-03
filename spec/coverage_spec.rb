# frozen_string_literal: true

require_relative '../lib/openapi_first/coverage'

RSpec.describe OpenapiFirst::Coverage do
  after(:each) do
    described_class.reset
  end

  let(:spec) do
    {
      'openapi' => '3.1.0',
      'paths' => {
        '/stuff/{id}' => {
          'parameters' => [
            {
              'name' => 'id',
              'in' => 'path',
              'required' => true,
              'schema' => {
                'type' => 'integer'
              }
            }
          ],
          'get' => {
            'responses' => {
              '200' => {
                'content' => {
                  'application/json' => {
                    'schema' => {
                      'type' => 'object'
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  end

  let(:definition) { OpenapiFirst.parse(spec, filepath: 'myopenapi.yaml') }

  describe '.register' do
    it 'accepts a filepath' do
      expect(described_class.register('spec/data/petstore.yaml')).to be_truthy
    end
  end

  describe '.report' do
    before do
      allow(OpenapiFirst).to receive(:load).with(definition.filepath) { definition }
      described_class.register(definition.filepath)
    end

    context 'with full coverage' do
      before do
        rack_request = Rack::Request.new(Rack::MockRequest.env_for('/stuff/1'))
        definition.validate_request(rack_request)
        rack_response = Rack::Response.new(JSON.dump({}), 200, { 'Content-Type' => 'application/json' })
        definition.validate_response(rack_request, rack_response)
      end

      it 'logs the coverage' do
        expect(described_class).not_to receive(:warn)
        expect(described_class).to receive(:puts).with(/fully covered/)
        described_class.report
      end
    end

    context 'with partly coverage' do
      before do
        rack_request = Rack::Request.new(Rack::MockRequest.env_for('/stuff/1'))
        definition.validate_request(rack_request)
      end

      it 'warns' do
        expect(described_class).to receive(:warn).with(/not fully covered/)
        described_class.report
      end
    end

    context 'without any requests' do
      it 'warns' do
        expect(described_class).to receive(:warn).with(/not detect any requests/)
        described_class.report
      end
    end
  end
end
