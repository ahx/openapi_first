# frozen_string_literal: true

RSpec.describe OpenapiFirst::Router::ResponseMatcher do
  def build_matcher(responses)
    described_class.new.tap do |matcher|
      responses.each do |response|
        matcher.add_response(response.status, response.content_type, response)
      end
    end
  end

  describe '#match' do
    it 'finds the matching response object for a status code' do
      responses = [
        double(status: '200', content_type: 'application/json'),
        double(status: '201', content_type: 'application/json')
      ]
      matcher = build_matcher(responses)
      expect(matcher.match(200, 'application/json').response).to eq(responses[0])
    end

    it 'finds a default status' do
      responses = [
        double(status: 'default', content_type: 'application/json'),
        double(status: '201', content_type: 'application/json')
      ]
      matcher = build_matcher(responses)
      expect(matcher.match(400, 'application/json').response).to eq(responses[0])
    end

    it 'finds a YXX status' do
      responses = [
        double(status: '200', content_type: 'application/json'),
        double(status: '2XX', content_type: 'application/json')
      ]
      matcher = build_matcher(responses)
      expect(matcher.match(201, 'application/json').response).to eq(responses[1])
    end

    it 'finds a Yxx status' do
      responses = [
        double(status: '200', content_type: 'application/json'),
        double(status: '2xx', content_type: 'application/json')
      ]
      matcher = build_matcher(responses)
      expect(matcher.match(201, 'application/json').response).to eq(responses[1])
    end

    it 'finds text/* wildcard content-type matcher' do
      responses = [
        double(status: '200', content_type: 'application/json'),
        double(status: '200', content_type: 'text/*')
      ]
      matcher = build_matcher(responses)
      expect(matcher.match(200, 'text/markdown').response).to eq(responses[1])
    end

    context 'when status code cannot be found' do
      it 'returns an error' do
        responses = [
          double(status: '200', content_type: nil),
          double(status: '201', content_type: nil)
        ]
        matcher = build_matcher(responses)
        expect(matcher.match(409, 'application/json')).to have_attributes(
          response: nil, error: have_attributes(
            error_type: :response_not_found,
            message: 'Response status 409 is not defined. Defined statuses are: 200, 201.'
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
        matcher = build_matcher(responses)
        expect(matcher.match(200, 'application/json')).to have_attributes(
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
        matcher = build_matcher(responses)
        message = 'Content-Type application/json is not defined. Content-Type should be application/text or application/xml.'
        expect(matcher.match(200, 'application/json')).to have_attributes(
          response: nil,
          error: have_attributes(error_type: :response_not_found, message:)
        )
      end
    end

    context 'when no content-type is defined' do
      it 'returns the response without content' do
        responses = [
          double(status: '204', content_type: nil),
          double(status: 'default', content_type: 'application/json')
        ]
        matcher = build_matcher(responses)
        expect(matcher.match(204, nil).response).to be(responses[0])
      end
    end
  end
end
