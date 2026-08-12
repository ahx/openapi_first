# frozen_string_literal: true

RSpec.describe OpenapiFirst::Request do
  describe '#parameters' do
    let(:definition) do
      OpenapiFirst.parse({
                           'openapi' => '3.1.0',
                           'paths' => {
                             '/stuff/{id}' => {
                               'parameters' => [
                                 { 'name' => 'id', 'in' => 'path', 'required' => true,
                                   'schema' => { 'type' => 'integer' } }
                               ],
                               'get' => {
                                 'parameters' => [
                                   { 'name' => 'Accept', 'in' => 'header' },
                                   { 'name' => 'tags', 'in' => 'query', 'style' => 'form', 'explode' => false,
                                     'deprecated' => true, 'schema' => { 'type' => 'array' } },
                                   { 'name' => 'X-Key', 'in' => 'header', 'required' => true,
                                     'schema' => { 'type' => 'string' } },
                                   { 'name' => 'session', 'in' => 'cookie', 'schema' => { 'type' => 'string' } },
                                   { 'name' => 'filter', 'in' => 'query',
                                     'content' => { 'application/json' => { 'schema' => { 'type' => 'object' } } } }
                                 ]
                               }
                             }
                           }
                         })
    end

    let(:request_definition) do
      definition.validate_request(Rack::Request.new(Rack::MockRequest.env_for('/stuff/1'))).request_definition
    end

    it 'returns the parameters of the operation and the path item, grouped by location' do
      expect(request_definition.parameters.map(&:name)).to eq(%w[id tags filter X-Key session])
      expect(request_definition.parameters.map(&:location)).to eq(%w[path query query header cookie])
    end

    it 'describes a parameter' do
      parameter = request_definition.parameters.find { _1.name == 'tags' }
      expect(parameter).to have_attributes(
        name: 'tags',
        location: 'query',
        style: 'form',
        explode?: false,
        required?: false,
        deprecated?: true,
        media_type: nil,
        schema: { 'type' => 'array' }
      )
    end

    it 'knows that path parameters are required' do
      parameter = request_definition.parameters.find { _1.name == 'id' }
      expect(parameter).to have_attributes(required?: true, deprecated?: false, schema: { 'type' => 'integer' })
    end

    it 'describes a parameter that uses content' do
      parameter = request_definition.parameters.find { _1.name == 'filter' }
      expect(parameter).to have_attributes(media_type: 'application/json', schema: { 'type' => 'object' })
    end

    it 'excludes parameters that openapi_first ignores' do
      expect(request_definition.parameters.map(&:name)).not_to include('Accept')
    end

    it 'returns a frozen Array' do
      expect(request_definition.parameters).to be_frozen
    end

    context 'without parameters' do
      let(:definition) do
        OpenapiFirst.parse({ 'openapi' => '3.1.0', 'paths' => { '/stuff/{id}' => { 'get' => {} } } })
      end

      it 'is empty' do
        expect(request_definition.parameters).to eq([])
      end
    end
  end
end
