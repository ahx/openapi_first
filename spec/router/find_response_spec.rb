# frozen_string_literal: true

RSpec.describe OpenapiFirst::Router::FindResponse do
  describe '.find' do
    def find(responses, status, content_type)
      groups = responses.each_with_object({}) do |response, hash|
        (hash[response.status] ||= {})[response.content_type] = response
      end
      described_class.call(groups, status, content_type, request_method: 'GET', path: '/stations')
    end

    it 'finds the matching response object for a status code' do
      responses = [
        double(status: '200', content_type: 'application/json'),
        double(status: '201', content_type: 'application/json')
      ]
      expect(find(responses, 200, 'application/json').response).to eq(responses[0])
    end

    it 'finds a default status' do
      responses = [
        double(status: 'default', content_type: 'application/json'),
        double(status: '201', content_type: 'application/json')
      ]
      expect(find(responses, 400, 'application/json').response).to eq(responses[0])
    end

    it 'finds a YXX status' do
      responses = [
        double(status: '200', content_type: 'application/json'),
        double(status: '2XX', content_type: 'application/json')
      ]
      expect(find(responses, 201, 'application/json').response).to eq(responses[1])
    end

    it 'finds a Yxx status' do
      responses = [
        double(status: '200', content_type: 'application/json'),
        double(status: '2xx', content_type: 'application/json')
      ]
      expect(find(responses, 201, 'application/json').response).to eq(responses[1])
    end

    it 'finds text/* wildcard content-type matcher' do
      responses = [
        double(status: '200', content_type: 'application/json'),
        double(status: '200', content_type: 'text/*')
      ]
      expect(find(responses, 200, 'text/markdown').response).to eq(responses[1])
    end

    context 'when status code cannot be found' do
      it 'returns an error' do
        responses = [
          double(status: '200', content_type: nil),
          double(status: '201', content_type: nil)
        ]
        expect(find(responses, 409, 'application/json')).to have_attributes(
          response: nil, error: have_attributes(
            type: :response_not_found,
            message: 'Status 409 is not defined for GET /stations. Defined statuses are: 200, 201.'
          )
        )
      end
    end

    context 'when API description has integers as status' do
      it 'just works, even though OAS wants strings' do
        responses = [
          double(status: 200, content_type: 'application/json'),
          double(status: '201', content_type: 'application/json')
        ]
        expect(find(responses, 200, 'application/json')).to have_attributes(
          response: responses[0]
        )
      end
    end

    context 'when content type cannot be found' do
      it 'returns a mismatch' do
        responses = [
          double(status: '200', content_type: 'application/text'),
          double(status: '200', content_type: 'application/xml')
        ]
        message = 'Content-Type should be application/text or application/xml, but was application/json for GET /stations'
        expect(find(responses, 200, 'application/json')).to have_attributes(
          response: nil,
          error: have_attributes(type: :response_not_found, message:)
        )
      end
    end

    context 'when no content-type is defined' do
      it 'returns the response without content' do
        responses = [
          double(status: '204', content_type: nil),
          double(status: 'default', content_type: 'application/json')
        ]
        expect(find(responses, 204, nil).response).to be(responses[0])
      end
    end
  end
end
