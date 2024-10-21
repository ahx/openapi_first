# frozen_string_literal: true

RSpec.describe OpenapiFirst::ResponseValidator do
  subject(:validator) do
    response_definition = instance_double(OpenapiFirst::Response,
                                          status: '200',
                                          content_type: 'application/json',
                                          content_schema: JSONSchemer.schema({
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
                                                                             }),
                                          headers: {},
                                          headers_schema: nil)
    described_class.new(response_definition, openapi_version: '3.1')
  end

  context 'with a valid response' do
    let(:parsed_response) do
      double(
        body: [
          { 'id' => 42, 'name' => 'hans' },
          { 'id' => 2, 'name' => 'Voldemort' }
        ],
        headers: {}
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
    context 'with missing property' do
      let(:parsed_response) do
        double(
          body: [
            { 'id' => 42 }
          ],
          headers: {}
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
          headers: {}
        )
      end

      it 'fails' do
        expect(subject.call(parsed_response).type).to eq(:invalid_response_body)
      end
    end
  end
end
