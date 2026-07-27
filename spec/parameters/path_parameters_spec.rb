# frozen_string_literal: true

RSpec.describe OpenapiFirst::Parameters::Parser do
  def unpack(definitions, path_params)
    definitions = [definitions] unless definitions.is_a?(Array)
    described_class.new(build_parameters(definitions)).unpack(path_params)
  end

  describe 'path parameters' do
    it 'returns the converted value' do
      parameter = { 'in' => 'path', 'name' => 'id', 'schema' => { 'type' => 'integer' } }
      expect(unpack(parameter, { 'id' => '12' })).to eq('id' => 12)
    end

    it 'excludes unknown keys' do
      parameter = { 'in' => 'path', 'name' => 'id', 'schema' => { 'type' => 'string' } }
      expect(unpack(parameter, { 'a' => 'b' })).to eq({})
    end

    describe 'Primitive parameter' do
      it 'returns multiple values' do
        parameters = [
          { 'in' => 'path', 'name' => 'id', 'schema' => { 'type' => 'integer' } },
          { 'in' => 'path', 'name' => 'year', 'schema' => { 'type' => 'integer' } }
        ]
        expect(unpack(parameters, { 'id' => '12', 'year' => '2022' })).to eq('id' => 12, 'year' => 2022)
      end

      it 'supports /{start_date}..{end_date}' do
        parameters = [
          { 'in' => 'path', 'name' => 'start_date' },
          { 'in' => 'path', 'name' => 'end_date' }
        ]
        path_params = { 'start_date' => '2021-01-01', 'end_date' => '2021-01-31' }
        expect(unpack(parameters, path_params)).to eq(path_params)
      end
    end

    describe 'Array explode true' do
      it 'returns an array' do
        parameter = {
          'in' => 'path', 'name' => 'id', 'explode' => true, 'schema' => { 'type' => 'array' }
        }
        expect(unpack(parameter, { 'id' => '1,2' })).to eq('id' => %w[1 2])
      end

      it 'excludes key if parameter is not set' do
        parameter = {
          'in' => 'path', 'name' => 'id', 'explode' => true, 'schema' => { 'type' => 'array' }
        }
        expect(unpack(parameter, {})).to eq({})
      end

      it 'returns an empty array if the value is empty' do
        parameter = {
          'in' => 'path', 'name' => 'id', 'explode' => true, 'schema' => { 'type' => 'array' }
        }
        expect(unpack(parameter, { 'id' => '' })).to eq('id' => [])
      end

      it 'supports the simple style' do
        parameter = {
          'in' => 'path', 'name' => 'id', 'style' => 'simple', 'explode' => true,
          'schema' => { 'type' => 'array' }
        }
        expect(unpack(parameter, { 'id' => '1,2' })).to eq('id' => %w[1 2])
      end

      it 'supports the label style' do
        parameter = {
          'in' => 'path', 'name' => 'color', 'explode' => true, 'style' => 'label',
          'schema' => { 'type' => 'array' }
        }
        expect(unpack(parameter, { 'color' => '.blue.black.brown' })).to eq('color' => %w[blue black brown])
      end

      it 'supports the matrix style' do
        parameter = {
          'in' => 'path', 'name' => 'color', 'explode' => true, 'style' => 'matrix',
          'schema' => { 'type' => 'array' }
        }
        path_params = { 'color' => ';color=blue;color=black;color=brown' }
        expect(unpack(parameter, path_params)).to eq('color' => %w[blue black brown])
      end
    end

    describe 'Array explode false' do
      it 'returns an array' do
        parameter = {
          'in' => 'path', 'name' => 'id', 'explode' => false, 'schema' => { 'type' => 'array' }
        }
        expect(unpack(parameter, { 'id' => '1,2' })).to eq('id' => %w[1 2])
      end

      it 'supports the simple style' do
        parameter = {
          'in' => 'path', 'name' => 'id', 'style' => 'simple', 'explode' => false,
          'schema' => { 'type' => 'array' }
        }
        expect(unpack(parameter, { 'id' => '1,2' })).to eq('id' => %w[1 2])
      end

      it 'supports the label style' do
        parameter = {
          'in' => 'path', 'name' => 'id', 'explode' => false, 'style' => 'label',
          'schema' => { 'type' => 'array' }
        }
        expect(unpack(parameter, { 'id' => '.1.2' })).to eq('id' => %w[1 2])
      end

      it 'supports the matrix style' do
        parameter = {
          'in' => 'path', 'name' => 'color', 'explode' => false, 'style' => 'matrix',
          'schema' => { 'type' => 'array' }
        }
        path_params = { 'color' => ';color=blue,black,brown' }
        expect(unpack(parameter, path_params)).to eq('color' => %w[blue black brown])
      end

      it 'returns an empty array if a matrix style value is empty' do
        parameter = {
          'in' => 'path', 'name' => 'color', 'explode' => false, 'style' => 'matrix',
          'schema' => { 'type' => 'array' }
        }
        expect(unpack(parameter, { 'color' => '' })).to eq('color' => [])
      end
    end

    describe 'Object explode true' do
      it 'applies the "simple" style by default' do
        parameter = {
          'in' => 'path', 'name' => 'color', 'explode' => true, 'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, { 'color' => 'R=100,G=200,B=150' })).to eq(
          'color' => { 'R' => '100', 'G' => '200', 'B' => '150' }
        )
      end

      it 'excludes key if not set' do
        parameter = {
          'in' => 'path', 'name' => 'id', 'explode' => true, 'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, {})).to eq({})
      end

      it 'accepts the "simple" style' do
        parameter = {
          'in' => 'path', 'name' => 'color', 'explode' => true, 'style' => 'simple',
          'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, { 'color' => 'R=100,G=200,B=150' })).to eq(
          'color' => { 'R' => '100', 'G' => '200', 'B' => '150' }
        )
      end

      it 'returns the unpacked value if value is malformated' do
        parameter = {
          'in' => 'path', 'name' => 'color', 'explode' => true, 'style' => 'simple',
          'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, { 'color' => 'R=100,G200,B=150' })).to eq(
          'color' => { 'B' => '150', 'G200' => nil, 'R' => '100' }
        )
      end
    end

    describe 'Object explode false' do
      it 'applies the "simple" style and explode false by default' do
        parameter = { 'in' => 'path', 'name' => 'color', 'schema' => { 'type' => 'object' } }
        expect(unpack(parameter, { 'color' => 'R,100,G,200,B,150' })).to eq(
          'color' => { 'R' => '100', 'G' => '200', 'B' => '150' }
        )
      end

      it 'returns the unpacked value if value is malformated' do
        parameter = {
          'in' => 'path', 'name' => 'color', 'style' => 'simple', 'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, { 'color' => 'R,100,G200,B,150' })).to eq('color' => 'R,100,G200,B,150')
      end

      it 'accepts "simple" style' do
        parameter = {
          'in' => 'path', 'name' => 'color', 'explode' => false, 'style' => 'simple',
          'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, { 'color' => 'R,100,G,200,B,150' })).to eq(
          'color' => { 'R' => '100', 'G' => '200', 'B' => '150' }
        )
      end

      it 'accepts "matrix" style' do
        parameter = {
          'in' => 'path', 'name' => 'color', 'explode' => false, 'style' => 'matrix',
          'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, { 'color' => ';color=R,100,G,200,B,150' })).to eq(
          'color' => { 'R' => '100', 'G' => '200', 'B' => '150' }
        )
      end

      it 'accepts "label" style' do
        parameter = {
          'in' => 'path', 'name' => 'color', 'explode' => false, 'style' => 'label',
          'schema' => { 'type' => 'object' }
        }
        expect(unpack(parameter, { 'color' => '.R.100.G.200.B.150' })).to eq(
          'color' => { 'R' => '100', 'G' => '200', 'B' => '150' }
        )
      end
    end
  end
end
