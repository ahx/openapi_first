# frozen_string_literal: true

RSpec.describe OpenapiFirst::Parameters::Parameter do
  describe '#name' do
    it 'returns the name' do
      parameter = build_parameter({ 'in' => 'query', 'name' => 'id' })
      expect(parameter.name).to eq 'id'
    end
  end

  describe '#convert' do
    it 'converts the value' do
      parameter = build_parameter({ 'in' => 'query', 'name' => 'id', 'schema' => { 'type' => 'integer' } })
      expect(parameter.convert('2')).to eq 2
    end
  end

  describe '#location' do
    it 'returns the "in" value' do
      parameter = build_parameter({ 'in' => 'query', 'name' => 'id' })
      expect(parameter.location).to eq 'query'
    end
  end

  describe '#schema' do
    it 'returns the schema' do
      parameter = build_parameter({ 'in' => 'query', 'name' => 'id', 'schema' => { 'type' => 'string' } })
      expect(parameter.schema).to eq({ 'type' => 'string' })
    end
  end

  describe '#array?' do
    it 'returns true if type is array' do
      parameter = build_parameter({ 'in' => 'query', 'schema' => { 'type' => 'array' } })
      expect(parameter.array?).to be true
    end

    it 'returns false if type is not array' do
      parameter = build_parameter({ 'in' => 'query', 'schema' => { 'type' => 'string' } })
      expect(parameter.array?).to be false
    end
  end

  describe '#object?' do
    it 'returns true if type is object' do
      parameter = build_parameter({ 'in' => 'query', 'schema' => { 'type' => 'object' } })
      expect(parameter.object?).to be true
    end

    it 'returns true if style is deepObject' do
      parameter = build_parameter({ 'in' => 'query', 'style' => 'deepObject' })
      expect(parameter.object?).to be true
    end

    it 'returns true if schema defines properties' do
      parameter = build_parameter(
        { 'in' => 'query', 'schema' => { 'properties' => { 'a' => { 'type' => 'string' } } } }
      )
      expect(parameter.object?).to be true
    end

    it 'returns false if type is not object' do
      parameter = build_parameter({ 'in' => 'query', 'schema' => { 'type' => 'string' } })
      expect(parameter.object?).to be false
    end
  end

  describe '#deep_object?' do
    it 'returns true if style is deepObject' do
      parameter = build_parameter({ 'in' => 'query', 'style' => 'deepObject' })
      expect(parameter.deep_object?).to be true
    end

    it 'returns false if style is not deepObject' do
      parameter = build_parameter({ 'in' => 'query' })
      expect(parameter.deep_object?).to be false
    end
  end

  describe '#style' do
    it 'returns the style if defined' do
      parameter = build_parameter({ 'in' => 'query', 'style' => 'spaceDelimited' })
      expect(parameter.style).to eq 'spaceDelimited'
    end

    it 'returns "form" for query parameters' do
      parameter = build_parameter({ 'in' => 'query' })
      expect(parameter.style).to eq 'form'
    end

    it 'returns "simple" for path parameters' do
      parameter = build_parameter({ 'in' => 'path' })
      expect(parameter.style).to eq 'simple'
    end

    it 'returns "simple" for header parameters' do
      parameter = build_parameter({ 'in' => 'header' })
      expect(parameter.style).to eq 'simple'
    end

    it 'returns "form" for cookie parameters' do
      parameter = build_parameter({ 'in' => 'cookie' })
      expect(parameter.style).to eq 'form'
    end
  end

  describe '#explode?' do
    it 'returns true if explode is true' do
      parameter = build_parameter({ 'in' => 'query', 'explode' => true })
      expect(parameter.explode?).to be true
    end

    it 'returns false if explode is false' do
      parameter = build_parameter({ 'in' => 'query', 'explode' => false })
      expect(parameter.explode?).to be false
    end

    describe 'when explode is not specified' do
      it 'returns true if style is "form"' do
        parameter = build_parameter({ 'in' => 'query', 'style' => 'form' })
        expect(parameter.explode?).to be true
      end

      it 'returns false if style is not "form"' do
        parameter = build_parameter({ 'in' => 'query', 'style' => 'spaceDelimited' })
        expect(parameter.explode?).to be false
      end
    end
  end

  describe '#media_type' do
    it 'returns the media type' do
      parameter = build_parameter(
        { 'in' => 'query', 'content' => { 'application/json' => { 'schema' => { 'type' => 'string' } } } }
      )
      expect(parameter.media_type).to eq 'application/json'
    end

    it 'returns nil if "content" is not defined' do
      parameter = build_parameter({ 'in' => 'query' })
      expect(parameter.media_type).to be_nil
    end
  end

  describe '#unpack' do
    it 'returns nil if the value is nil' do
      parameter = build_parameter({ 'in' => 'query', 'name' => 'id', 'schema' => { 'type' => 'string' } })
      expect(parameter.unpack(nil)).to be_nil
    end

    it 'parses a value of a parameter with a JSON media type' do
      parameter = build_parameter(
        { 'in' => 'query', 'name' => 'filter',
          'content' => { 'application/json' => { 'schema' => { 'type' => 'object' } } } }
      )
      expect(parameter.unpack('{"a":1}')).to eq({ 'a' => 1 })
    end

    it 'returns the value as is if a parameter with an unknown media type' do
      parameter = build_parameter(
        { 'in' => 'query', 'name' => 'filter',
          'content' => { 'application/xml' => { 'schema' => { 'type' => 'object' } } } }
      )
      expect(parameter.unpack('<a>1</a>')).to eq('<a>1</a>')
    end
  end
end
