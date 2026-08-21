# frozen_string_literal: true

RSpec.describe OpenapiFirst::ParametersParser do
  def unpack(definitions, headers)
    definitions = [definitions] unless definitions.is_a?(Array)
    described_class.new(build_parameters(definitions)).unpack(headers)
  end

  describe 'header parameters' do
    it 'returns the converted value' do
      parameter = { 'in' => 'header', 'name' => 'X-Some', 'schema' => { 'type' => 'integer' } }
      expect(unpack(parameter, { 'X-Some' => '12' })).to eq('X-Some' => 12)
    end

    it 'excludes unknown headers' do
      parameter = { 'in' => 'header', 'name' => 'X-Some', 'schema' => { 'type' => 'string' } }
      expect(unpack(parameter, { 'X-Some' => 'abc', 'X-Unknown' => 'xyz' })).to eq('X-Some' => 'abc')
    end

    describe 'with RequestHeaders' do
      it 'finds headers in a Rack env' do
        parameter = { 'in' => 'header', 'name' => 'X-Some' }
        headers = OpenapiFirst::RequestHeaders.new({ 'HTTP_X_SOME' => 'abc' })
        expect(unpack(parameter, headers)).to eq('X-Some' => 'abc')
      end

      it 'finds headers that are not prefixed with HTTP_ in a Rack env' do
        parameters = [
          { 'in' => 'header', 'name' => 'Content-Length', 'schema' => { 'type' => 'integer' } },
          { 'in' => 'header', 'name' => 'Content-Type' }
        ]
        env = { 'CONTENT_LENGTH' => '12', 'CONTENT_TYPE' => 'application/json' }
        headers = OpenapiFirst::RequestHeaders.new(env)
        expect(unpack(parameters, headers)).to eq('Content-Length' => 12, 'Content-Type' => 'application/json')
      end
    end

    describe 'Primitive parameter' do
      it 'returns a string' do
        parameter = { 'in' => 'header', 'name' => 'X-Some', 'schema' => { 'type' => 'string' } }
        expect(unpack(parameter, { 'X-Some' => '12' })).to eq('X-Some' => '12')
      end

      it 'does not add key if not set' do
        parameter = { 'in' => 'header', 'name' => 'X-Some', 'schema' => { 'type' => 'integer' } }
        expect(unpack(parameter, {})).to eq({})
      end

      it 'works with special characters in names' do
        parameter = { 'in' => 'header', 'name' => '[]some[things]%', 'schema' => { 'type' => 'integer' } }
        expect(unpack(parameter, { '[]some[things]%' => '12' })).to eq('[]some[things]%' => 12)
      end
    end

    describe 'Array explode true' do
      it 'returns an array' do
        parameter = {
          'in' => 'header', 'name' => 'X-Some', 'explode' => true, 'schema' => { 'type' => 'array' }
        }
        expect(unpack(parameter, { 'X-Some' => '1,2' })).to eq('X-Some' => %w[1 2])
      end

      it 'excludes key if not set' do
        parameter = {
          'in' => 'header', 'name' => 'X-Some', 'explode' => true, 'schema' => { 'type' => 'array' }
        }
        expect(unpack(parameter, {})).to eq({})
      end
    end

    describe 'Array explode false' do
      it 'returns an array' do
        parameter = {
          'in' => 'header', 'name' => 'X-Some', 'explode' => false, 'schema' => { 'type' => 'array' }
        }
        expect(unpack(parameter, { 'X-Some' => '1,2' })).to eq('X-Some' => %w[1 2])
      end
    end

    describe 'Object explode true' do
      it 'applies the "simple" style by default' do
        parameter = {
          'in' => 'header', 'name' => 'X-Some', 'explode' => true, 'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, { 'X-Some' => 'R=100,G=200,B=150' })).to eq(
          'X-Some' => { 'R' => '100', 'G' => '200', 'B' => '150' }
        )
      end

      it 'excludes if not set' do
        parameter = {
          'in' => 'header', 'name' => 'X-Some', 'explode' => true, 'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, {})).to eq({})
      end

      it 'accepts the "simple" style' do
        parameter = {
          'in' => 'header', 'name' => 'X-Some', 'explode' => true, 'style' => 'simple',
          'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, { 'X-Some' => 'R=100,G=200,B=150' })).to eq(
          'X-Some' => { 'R' => '100', 'G' => '200', 'B' => '150' }
        )
      end

      it 'returns the unpacked value if value is malformated' do
        parameter = {
          'in' => 'header', 'name' => 'X-Some', 'explode' => true, 'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, { 'X-Some' => 'R=100,G200,B=150' })).to eq('X-Some' => 'R=100,G200,B=150')
      end
    end

    describe 'Object explode false' do
      it 'applies the "simple" style and explode false by default' do
        parameter = { 'in' => 'header', 'name' => 'X-Some', 'schema' => { 'type' => 'object' } }
        expect(unpack(parameter, { 'X-Some' => 'R,100,G,200,B,150' })).to eq(
          'X-Some' => { 'R' => '100', 'G' => '200', 'B' => '150' }
        )
      end

      it 'returns the unpacked value if value is malformated' do
        parameter = { 'in' => 'header', 'name' => 'X-Some', 'schema' => { 'type' => 'object' } }
        expect(unpack(parameter, { 'X-Some' => 'R,100,G200,B,150' })).to eq('X-Some' => 'R,100,G200,B,150')
      end

      it 'accepts the "simple" style' do
        parameter = {
          'in' => 'header', 'name' => 'X-Some', 'explode' => false, 'style' => 'simple',
          'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, { 'X-Some' => 'R,100,G,200,B,150' })).to eq(
          'X-Some' => { 'R' => '100', 'G' => '200', 'B' => '150' }
        )
      end
    end
  end
end
