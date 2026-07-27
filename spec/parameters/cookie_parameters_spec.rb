# frozen_string_literal: true

RSpec.describe OpenapiFirst::Parameters::Parser do
  def unpack(definitions, cookie_string)
    definitions = [definitions] unless definitions.is_a?(Array)
    described_class.new(build_parameters(definitions)).unpack(Rack::Utils.parse_cookies_header(cookie_string))
  end

  describe 'cookie parameters' do
    it 'returns the converted value' do
      parameter = { 'in' => 'cookie', 'name' => 'Some', 'schema' => { 'type' => 'integer' } }
      expect(unpack(parameter, 'Some=12;')).to eq('Some' => 12)
    end

    describe 'No schema type defined' do
      it 'returns the cookie value' do
        parameter = { 'in' => 'cookie', 'name' => 'Some', 'schema' => {} }
        expect(unpack(parameter, 'Some=abc;')).to eq('Some' => 'abc')
      end
    end

    it 'excludes unknown cookies' do
      parameter = { 'in' => 'cookie', 'name' => 'Some' }
      expect(unpack(parameter, 'Other=cde; Some=abc;')).to eq('Some' => 'abc')
    end

    describe 'Primitive parameter' do
      it 'returns the cookie value' do
        parameter = { 'in' => 'cookie', 'name' => 'Some', 'schema' => { 'type' => 'integer' } }
        expect(unpack(parameter, 'Some=12;')).to eq('Some' => 12)
      end

      it 'excludes key if parameter not set' do
        parameter = { 'in' => 'cookie', 'name' => 'Some', 'schema' => { 'type' => 'integer' } }
        expect(unpack(parameter, '')).to eq({})
      end

      it 'works with special characters in names' do
        parameter = { 'in' => 'cookie', 'name' => '[]some[things]%', 'schema' => { 'type' => 'integer' } }
        expect(unpack(parameter, '[]some[things]%=12;')).to eq('[]some[things]%' => 12)
      end
    end

    describe 'Array explode true' do
      # NOTE: Nobody seems to understand how explode: true should work for arrays in cookie parameters.
      # So the explode flag is ignored for arrays.
      it 'returns an array' do
        parameter = {
          'in' => 'cookie', 'name' => 'Some', 'explode' => true, 'schema' => { 'type' => 'array' }
        }
        expect(unpack(parameter, 'Some=1,2;')).to eq('Some' => %w[1 2])
      end
    end

    describe 'Array explode false' do
      it 'returns an array' do
        parameter = {
          'in' => 'cookie', 'name' => 'Some', 'explode' => false, 'schema' => { 'type' => 'array' }
        }
        expect(unpack(parameter, 'Some=1,2;')).to eq('Some' => %w[1 2])
      end

      it 'excludes key if parameter is not set' do
        parameter = {
          'in' => 'cookie', 'name' => 'Some', 'explode' => false, 'schema' => { 'type' => 'array' }
        }
        expect(unpack(parameter, '')).to eq({})
      end
    end

    describe 'Object explode true' do
      # NOTE: Nobody seems to understand how explode: true should work
      # So the explode flag is ignored for objects.
      it 'applies the "form" style by default' do
        parameter = {
          'in' => 'cookie', 'name' => 'Some', 'explode' => true, 'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, 'Some=R=100,G=200,B=150;')).to eq(
          'Some' => { 'R' => '100', 'G' => '200', 'B' => '150' }
        )
      end

      it 'excludes key if parameter is not set' do
        parameter = {
          'in' => 'cookie', 'name' => 'Some', 'explode' => true, 'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, '')).to eq({})
      end

      it 'accepts the "form" style' do
        parameter = {
          'in' => 'cookie', 'name' => 'Some', 'explode' => true, 'style' => 'form',
          'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, 'Some=R=100,G=200,B=150;')).to eq(
          'Some' => { 'R' => '100', 'G' => '200', 'B' => '150' }
        )
      end

      it 'returns the unpacked value if value is malformated' do
        parameter = {
          'in' => 'cookie', 'name' => 'Some', 'explode' => true, 'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, 'Some=R=100,G200,B=150;')).to eq('Some' => 'R=100,G200,B=150')
      end
    end

    describe 'Object explode false' do
      it 'applies the "simple" style and explode false by default' do
        parameter = { 'in' => 'cookie', 'name' => 'Some', 'schema' => { 'type' => 'object' } }
        expect(unpack(parameter, 'Some=R,100,G,200,B,150;')).to eq(
          'Some' => { 'R' => '100', 'G' => '200', 'B' => '150' }
        )
      end

      it 'returns the unpacked value if value is malformated' do
        parameter = { 'in' => 'cookie', 'name' => 'Some', 'schema' => { 'type' => 'object' } }
        expect(unpack(parameter, 'Some=R,100,G200,B,150;')).to eq('Some' => 'R,100,G200,B,150')
      end

      it 'accepts the "simple" style' do
        parameter = {
          'in' => 'cookie', 'name' => 'Some', 'explode' => false, 'style' => 'simple',
          'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, 'Some=R,100,G,200,B,150;')).to eq(
          'Some' => { 'R' => '100', 'G' => '200', 'B' => '150' }
        )
      end
    end
  end
end
