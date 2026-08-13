# frozen_string_literal: true

require 'rack/test'
require_relative 'spec_helper'

RSpec.describe 'request/response validation examples' do
  include Rack::Test::Methods

  def send_request(request_example)
    method = request_example.fetch('method')
    uri = request_example.fetch('uri')
    return send(method, uri) unless request_example['body']

    send(method, uri, JSON.generate(request_example['body']),
         'CONTENT_TYPE' => request_example.fetch('content_type', 'application/json'))
  end

  Dir.glob(File.join(__dir__, '/test_cases/*.yaml')).each do |filepath|
    describe filepath do
      YAML.load_file(filepath).each do |example|
        context example['description'] do
          let(:oad) { example['oad'] }
          let(:definition) { OpenapiFirst.parse(oad, filepath:) }

          let(:app) do
            lambda do |_env|
              body = JSON.generate(response['body'])
              Rack::Response[
                response['status'] || 200,
                { 'Content-Type' => response['content_type'] || 'application/json' },
                [body]
              ].finish
            end
          end

          let(:test_path) do
            oad['paths'].keys.first
          end

          let(:request_method) do
            oad['paths'][test_path].keys.first.upcase
          end

          let(:response) do
            example['valid_response'] || { 'content_type' => 'application/json', 'body' => {} }
          end

          if example['valid_response']
            context 'with valid response' do
              let(:response) { example['valid_response'] }

              it 'passes validation' do
                send(request_method.downcase, test_path)

                request = Rack::Request.new(last_request.env)
                response = Rack::Response.new(
                  last_response.body,
                  last_response.status,
                  last_response.headers
                )

                validated = definition.validate_response(request, response)
                expect(validated).to be_valid
              end
            end
          end

          if example['invalid_response']
            context 'with invalid response' do
              let(:response) { example['invalid_response'] }

              it 'fails validation' do
                send(request_method.downcase, test_path)

                request = Rack::Request.new(last_request.env)
                response = Rack::Response.new(
                  last_response.body,
                  last_response.status,
                  last_response.headers
                )

                validated = definition.validate_response(request, response)
                expect(validated).not_to be_valid
                expect(validated.error).not_to be_nil
              end
            end
          end

          if example['valid_request']
            context 'with valid request' do
              it 'passes validation' do
                send_request(example['valid_request'])

                validated = definition.validate_request(last_request)
                expect(validated.error).to be_nil
                expect(validated).to be_valid
              end
            end
          end

          if example['invalid_request']
            context 'with invalid request' do
              it 'fails validation' do
                send_request(example['invalid_request'])

                validated = definition.validate_request(last_request)
                expect(validated.error).not_to be_nil
                expect(validated).to be_invalid
              end
            end
          end
        end
      end
    end
  end
end
