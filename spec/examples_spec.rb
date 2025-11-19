# frozen_string_literal: true

require 'rack/test'
require_relative 'spec_helper'

RSpec.describe 'request/response validation examples' do
  include Rack::Test::Methods

  # Load all examples from the YAML file
  examples = YAML.load_file(File.join(__dir__, 'examples.yaml'))

  examples.each do |example|
    context example['description'] do
      let(:oad) { example['oad'] }
      let(:definition) { OpenapiFirst.parse(oad) }

      let(:app) do
        lambda do |_env|
          body = if response['body'].is_a?(String)
                   response['body']
                 else
                   JSON.generate(response['body'])
                 end
          [
            response['status'] || 200,
            { 'Content-Type' => response['content_type'] || 'application/json' },
            [body]
          ]
        end
      end

      # Get the first path from the OAD
      let(:test_path) do
        oad['paths'].keys.first
      end

      # Get the HTTP method for the test path
      let(:test_method) do
        oad['paths'][test_path].keys.first.upcase
      end

      if example['valid_response']
        context 'with valid response' do
          let(:response) { example['valid_response'] }

          it 'passes validation' do
            send(test_method.downcase, test_path)

            request = Rack::Request.new(last_request.env)
            body = last_response.body.is_a?(String) ? last_response.body : last_response.body.join
            response = Rack::Response.new(
              body,
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
            send(test_method.downcase, test_path)

            request = Rack::Request.new(last_request.env)
            body = last_response.body.is_a?(String) ? last_response.body : last_response.body.join
            response = Rack::Response.new(
              body,
              last_response.status,
              last_response.headers
            )

            validated = definition.validate_response(request, response)
            expect(validated).not_to be_valid
            expect(validated.error).not_to be_nil
          end
        end
      end
    end
  end
end
