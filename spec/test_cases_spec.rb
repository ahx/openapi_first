# frozen_string_literal: true

require 'rack/test'
require_relative 'spec_helper'

RSpec.describe 'request/response validation examples' do
  include Rack::Test::Methods

  Dir.glob(File.join(__dir__, '/test_cases/*.yaml')).each do |filepath|
    describe filepath do
      YAML.load_file(filepath).each do |example|
        context example['description'] do
          let(:oad) { example['oad'] }
          let(:definition) { OpenapiFirst.parse(oad, filepath:) }

          let(:app) do
            lambda do |_env|
              body = response['body']
              body = JSON.generate(response['body']) unless response['body'].is_a?(String)
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
  end
end
