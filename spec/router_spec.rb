# frozen_string_literal: true

require 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first/router'

RSpec.describe OpenapiFirst::Router do
  include Rack::Test::Methods

  describe '#call' do
    let(:app) do
      Rack::Builder.new do
        use OpenapiFirst::Router,
            spec: OpenapiFirst.load('./spec/data/petstore.yaml')
        run ->(_env) { Rack::Response.new('hello', 200).finish }
      end
    end

    let(:path) do
      '/pets'
    end

    let(:query_params) do
      {}
    end

    it 'returns 404 if path is not found' do
      get '/unknown', query_params

      expect(last_response.status).to be 404
      expect(last_response.body).to eq 'Not Found'

      operation = last_request.env.fetch(OpenapiFirst::OPERATION)
      expect(operation).to be_nil
    end

    it 'returns 405 if method is not found' do
      query_params.delete('term')
      delete path, query_params

      expect(last_response.status).to be 405
      expect(last_response.body).to eq 'Not Allowed'

      operation = last_request.env.fetch(OpenapiFirst::OPERATION)
      expect(operation).to be_nil
    end

    it 'adds the operation to env ' do
      get path, query_params

      operation = last_request.env[OpenapiFirst::OPERATION]
      expect(operation.operation_id).to eq 'listPets'
    end

    describe 'respecting SCRIPT_NAME' do
      let(:failure_app) do
        ->(_env) { Rack::Response.new.finish  }
      end

      let(:upstream_app) do
        ->(_env) { Rack::Response.new.finish  }
      end

      let(:app) do
        OpenapiFirst::Router.new(
          upstream_app,
          parent_app: failure_app,
          spec: OpenapiFirst.load('./spec/data/petstore.yaml')
        )
      end

      it 'uses SCRIPT_NAME to build the whole path' do
        env = Rack::MockRequest.env_for('/42', script_name: '/pets')

        expect(upstream_app).to receive(:call).with(env)

        app.call(env)
        operation = env[OpenapiFirst::OPERATION]
        expect(operation.operation_id).to eq 'showPetById'

        expect(env[Rack::SCRIPT_NAME]).to eq '/pets'
        expect(env[Rack::PATH_INFO]).to eq '/42'
      end

      it 'calls parent app with original env if route was not found' do
        env = Rack::MockRequest.env_for('/42', script_name: '/unknown')

        expect(failure_app).to receive(:call) do |cenv|
          expect(cenv[Rack::SCRIPT_NAME]).to eq '/unknown'
          expect(cenv[Rack::PATH_INFO]).to eq '/42'
        end

        app.call(env)

        expect(env[Rack::SCRIPT_NAME]).to eq '/unknown'
        expect(env[Rack::PATH_INFO]).to eq '/42'
      end
    end

    describe 'when operation has no operationId' do
      let(:app) do
        Rack::Builder.new do
          use OpenapiFirst::Router,
              spec: OpenapiFirst.load('./spec/data/operation-id-missing.yaml'),
              raise_error: true
          run ->(_env) { Rack::Response.new('hello', 200).finish }
        end
      end

      it 'does not raise an error' do
        get '/pets'
        expect(last_response.status).to eq 200

        operation = last_request.env[OpenapiFirst::OPERATION]
        expect(operation.operation_id).to be_nil
      end
    end

    describe 'path parameters' do
      it 'adds path parameters to env ' do
        get '/pets/1'

        params = last_request.env[OpenapiFirst::PARAMETERS]
        expect(params).to eq(petId: '1')
      end

      it 'does not add path parameters if not defined for operation' do
        get 'pets'

        params = last_request.env[OpenapiFirst::PARAMETERS]
        expect(params).to be_empty
      end
    end

    describe 'query parameters' do
      it 'adds query parameters to env ' do
        get '/pets?limit=2'

        params = last_request.env[OpenapiFirst::PARAMETERS]
        expect(params).to eq(limit: '2')
      end
    end

    describe 'raise_error option' do
      let(:app) do
        val = option
        Rack::Builder.new do
          use OpenapiFirst::Router,
              spec: OpenapiFirst.load('./spec/data/petstore.yaml'),
              raise_error: val
          run lambda { |_env|
            Rack::Response.new('hello', 200).finish
          }
        end
      end

      describe 'with nil' do
        let(:option) { nil }

        it 'returns 404' do
          get '/unknown'

          expect(last_response.status).to eq 404
        end
      end

      describe 'with false' do
        let(:option) { false }

        it 'returns 404' do
          get '/unknown'

          expect(last_response.status).to eq 404
        end
      end

      describe 'with true' do
        let(:option) { true }

        it 'raises an error if path was not found' do
          msg = "Could not find definition for GET '/unknown' in API description ./spec/data/petstore.yaml"
          expect do
            get '/unknown'
          end.to raise_error OpenapiFirst::NotFoundError, msg
        end

        it 'raises an error if request method was not found' do
          msg = "Could not find definition for DELETE '/pets' in API description ./spec/data/petstore.yaml"
          expect do
            delete '/pets'
          end.to raise_error OpenapiFirst::NotFoundError, msg
        end
      end
    end

    describe 'not_found option' do
      let(:app) do
        val = option
        Rack::Builder.new do
          use OpenapiFirst::Router,
              spec: OpenapiFirst.load('./spec/data/petstore.yaml'),
              not_found: val
          run lambda { |_env|
            Rack::Response.new('hello', 200).finish
          }
        end
      end

      describe 'with nil' do
        let(:option) { nil }

        it 'returns 404' do
          get '/unknown'

          expect(last_response.status).to eq 404
        end
      end

      describe 'with :halt' do
        let(:option) { :halt }

        it 'returns 404' do
          get '/unknown'

          expect(last_response.status).to eq 404
        end
      end

      describe 'with :continue' do
        let(:option) { :continue }

        it 'calls the next app in the stack' do
          get '/unknown'
          expect(last_response.status).to eq 200
          expect(last_request.env[OpenapiFirst::OPERATION]).to be_nil
          expect(last_response.body).to eq 'hello'
        end

        describe 'when combined with raise_error: true' do
          let(:app) do
            Rack::Builder.new do
              use OpenapiFirst::Router,
                  spec: OpenapiFirst.load('./spec/data/petstore.yaml'),
                  not_found: :continue,
                  raise_error: true
              run lambda { |_env|
                Rack::Response.new('hello', 200).finish
              }
            end
          end

          it 'raises an error if path was not found' do
            msg = "Could not find definition for GET '/unknown' in API description ./spec/data/petstore.yaml"
            expect do
              get '/unknown'
            end.to raise_error OpenapiFirst::NotFoundError, msg
          end
        end
      end
    end
  end
end
