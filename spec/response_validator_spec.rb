# frozen_string_literal: true

RSpec.describe OpenapiFirst::ResponseValidator do
  let(:content_schema) do
    JSONSchemer.schema({
                         'type' => 'array',
                         'items' => {
                           'type' => 'object',
                           'required' => %w[id name],
                           'properties' => {
                             'id' => { 'type' => 'integer' },
                             'name' => { 'type' => 'string' },
                             'tag' => { 'type' => 'string' }
                           }
                         }
                       })
  end

  let(:headers) do
    nil
  end

  subject(:validator) do
    described_class.new(content_schema:, headers:)
  end

  context 'with a valid response' do
    let(:parsed_response) do
      double(
        body: [
          { 'id' => 42, 'name' => 'hans' },
          { 'id' => 2, 'name' => 'Voldemort' }
        ],
        headers: []
      )
    end

    it 'raises nothing' do
      subject.call(parsed_response)
    end

    context 'with additional, not required properties' do
      let(:parsed_response) do
        double(
          body: [
            { 'id' => 42, 'name' => 'hans', 'email' => 'h@example.com' }
          ],
          headers: {}
        )
      end

      it 'returns no errors' do
        expect(subject.call(parsed_response)).to be_nil
      end
    end
  end

  context 'with an invalid response' do
    context 'with an invalid header' do
      let(:content_schema) do
        nil
      end
      let(:headers) do
        [
          instance_double(OpenapiFirst::Header,
                          name: 'x-id',
                          schema: JSONSchemer.schema({ type: 'integer' }),
                          required?: false)
        ]
      end

      it 'fails' do
        parsed_response = double(headers: { 'x-id' => 'abc' })
        expect(subject.call(parsed_response).type).to eq(:invalid_response_header)
      end
    end

    context 'with missing property' do
      let(:parsed_response) do
        double(
          body: [
            { 'id' => 42 }
          ],
          headers: nil
        )
      end

      it 'fails' do
        expect(subject.call(parsed_response).type).to eq(:invalid_response_body)
      end
    end

    context 'with wrong property type' do
      let(:parsed_response) do
        double(
          body: [
            { 'id' => 'string', 'name' => 'hans' }
          ],
          headers: nil
        )
      end

      it 'fails' do
        expect(subject.call(parsed_response).type).to eq(:invalid_response_body)
      end
    end
  end
end
