# frozen_string_literal: true

RSpec.describe OpenapiFirst::FileLoader do
  describe '.load' do
    begin
      require 'multi_json'
      # :nocov:
      before do
        MultiJson.load_options = { symbolize_keys: true }
      end

      after do
        MultiJson.load_options = { symbolize_keys: false }
      end
      # :nocov:
    rescue LoadError # rubocop:disable Lint/SuppressedException
    end

    it 'loads .yaml' do
      contents = described_class.load('./spec/data/petstore.yaml')
      expect(contents['openapi']).to eq('3.0.0')
    end

    it 'loads .yml' do
      contents = described_class.load('./spec/data/petstore.yml')
      expect(contents['openapi']).to eq('3.0.0')
    end

    it 'loads YAML keys as strings' do
      Tempfile.create(['codes', '.yaml']) do |file|
        file.write("200:\n  description: ok\n")
        file.flush

        expect(described_class.load(file.path)).to eq({ '200' => { 'description' => 'ok' } })
      end
    end

    it 'names the file when YAML contains a value that cannot be represented' do
      Tempfile.create(['limits', '.yaml']) do |file|
        file.write("maximum: .inf\n")
        file.flush

        expect { described_class.load(file.path) }
          .to raise_error(OpenapiFirst::Error, /\ACould not load "#{Regexp.escape(file.path)}": Infinity/)
      end
    end

    it 'loads .json' do
      contents = described_class.load('./spec/data/petstore.json')
      expect(contents['openapi']).to eq('3.0.0')
    end

    it 'raises FileNotFoundError if file was not found' do
      expect { described_class.load('./spec/data/unknown.yaml') }.to raise_error(OpenapiFirst::FileNotFoundError, 'File not found "./spec/data/unknown.yaml"')
    end
  end
end
