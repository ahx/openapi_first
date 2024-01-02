# frozen_string_literal: true

require 'spec_helper'
require 'rack'
require 'rack/test'
require 'openapi_first/router'

RSpec.describe OpenapiFirst::Router do
  include Rack::Test::Methods

  let(:env_key) { OpenapiFirst::Router::RAW_PATH_PARAMS }

  describe '#call' do
    let(:app) do
      Rack::Builder.new do
        use OpenapiFirst::Router,
            spec: './spec/data/petstore.yaml'
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
      expect(last_response.body).to eq 'Method Not Allowed'

      operation = last_request.env.fetch(OpenapiFirst::OPERATION)
      expect(operation).to be_nil
    end

    it 'adds the operation to env ' do
      get path, query_params

      operation = last_request.env[OpenapiFirst::OPERATION]
      expect(operation.operation_id).to eq 'listPets'
    end

    describe 'initialize with path to spec' do
      let(:app) do
        Rack::Builder.new do
          use OpenapiFirst::Router,
              spec: './spec/data/petstore.yaml'
          run ->(_env) { Rack::Response.new('hello', 200).finish }
        end
      end

      it 'works as expected ' do
        get path, query_params

        operation = last_request.env[OpenapiFirst::OPERATION]
        expect(operation.operation_id).to eq 'listPets'
      end
    end

    describe 'respecting SCRIPT_NAME' do
      let(:upstream_app) do
        ->(_env) { Rack::Response.new.finish }
      end

      let(:app) do
        OpenapiFirst::Router.new(
          upstream_app,
          spec: './spec/data/petstore.yaml'
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
    end

    context 'when operation has no operationId' do
      let(:app) do
        Rack::Builder.new do
          use OpenapiFirst::Router,
              spec: './spec/data/operation-id-missing.yaml',
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

        params = last_request.env[env_key]
        expect(params['petId']).to eq('1')
      end

      it 'does not add path parameters if not defined for operation' do
        get 'pets'

        params = last_request.env[env_key]
        expect(params).to be_empty
      end

      describe 'path parameter patterns' do
        let(:app) do
          Rack::Builder.new do
            use OpenapiFirst::Router,
                spec: './spec/data/parameters-path.yaml',
                raise_error: true
            run ->(_env) { Rack::Response.new('hello', 200).finish }
          end
        end

        it 'supports /{date}' do
          get '/info/2020-01-01'
          expect(last_response.status).to eq 200

          operation = last_request.env[OpenapiFirst::OPERATION]
          expect(operation.operation_id).to eq 'info_date'

          params = last_request.env[env_key]
          expect(params['date']).to eq('2020-01-01')
        end

        pending 'supports /{start_date}..{end_date}' do
          get '/info/2020-01-01..2020-01-02'
          expect(last_response.status).to eq 200

          operation = last_request.env[OpenapiFirst::OPERATION]
          expect(operation.operation_id).to eq 'info_date_range'

          params = last_request.env[env_key]
          expect(params['start_date']).to eq('2020-01-01')
          expect(params['end_date']).to eq('2020-01-02')
        end

        it 'still works without parameters' do
          get '/info'
          expect(last_response.status).to eq 200

          operation = last_request.env[OpenapiFirst::OPERATION]
          expect(operation.operation_id).to eq 'info'

          params = last_request.env[env_key]
          expect(params).to be_empty
        end
      end
    end

    describe 'raise_error option' do
      let(:app) do
        val = option
        Rack::Builder.new do
          use OpenapiFirst::Router,
              spec: './spec/data/petstore.yaml',
              raise_error: val
          run lambda { |_env|
            Rack::Response.new('hello', 200).finish
          }
        end
      end

      context 'with nil' do
        let(:option) { nil }

        it 'returns 404' do
          get '/unknown'

          expect(last_response.status).to eq 404
        end
      end

      context 'with false' do
        let(:option) { false }

        it 'returns 404' do
          get '/unknown'

          expect(last_response.status).to eq 404
        end
      end

      context 'with true' do
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
              spec: './spec/data/petstore.yaml',
              not_found: val
          run lambda { |_env|
            Rack::Response.new('hello', 200).finish
          }
        end
      end

      context 'with nil' do
        let(:option) { nil }

        it 'returns 404' do
          get '/unknown'

          expect(last_response.status).to eq 404
        end
      end

      context 'with :halt' do
        let(:option) { :halt }

        it 'returns 404' do
          get '/unknown'

          expect(last_response.status).to eq 404
        end
      end

      context 'with :continue' do
        let(:option) { :continue }

        it 'calls the next app in the stack' do
          get '/unknown'
          expect(last_response.status).to eq 200
          expect(last_request.env[OpenapiFirst::OPERATION]).to be_nil
          expect(last_response.body).to eq 'hello'
        end

        context 'when combined with raise_error: true' do
          let(:app) do
            Rack::Builder.new do
              use OpenapiFirst::Router,
                  spec: './spec/data/petstore.yaml',
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

    describe 'GitHub issue #155' do
      let(:app) do
        Rack::Builder.new do
          use OpenapiFirst::Router, spec: './spec/data/incompatible-routes.yaml'
          run ->(_env) { Rack::Response.new('hello', 200).finish }
        end
      end

      it 'works with with different variables in common nested routes' do
        get 'foo/1'

        operation = last_request.env[OpenapiFirst::OPERATION]
        expect(operation.operation_id).to eq 'foo'

        get 'foo/1/bar'

        operation = last_request.env[OpenapiFirst::OPERATION]
        expect(operation.operation_id).to eq 'foo-bar'
      end
    end
  end
end
