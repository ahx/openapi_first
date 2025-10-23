# frozen_string_literal: true

require 'rack'
require 'rack/test'
require 'openapi_first'

RSpec.describe 'Request body validation' do
  let(:path) do
    '/pets'
  end

  def fixture_path(name)
    Pathname.new(Dir.pwd).join('spec', 'data', name).realpath
  end

  describe '#call' do
    include Rack::Test::Methods

    let(:raise_error_option) { false }

    let(:app) do
      raise_error = raise_error_option
      Rack::Builder.new do
        spec = './spec/data/request-body-validation.yaml'
        use(OpenapiFirst::Middlewares::RequestValidation, spec:, raise_error:)
        run lambda { |_env|
          Rack::Response.new('hello', 200).finish
        }
      end
    end

    let(:request_body) do
      {
        'type' => 'pet',
        'attributes' => {
          'name' => 'Oscar'
        }
      }
    end

    it 'works with stringio' do
      header Rack::CONTENT_TYPE, 'application/json'
      io = StringIO.new(JSON.generate(request_body))
      post path, io

      expect(last_response.status).to be 200
    end

    it 'succeeds with simple multipart form data' do
      header Rack::CONTENT_TYPE, 'multipart/form-data'
      post path, request_body

      expect(last_response.status).to be(200), last_response.body
      expect(last_request.env[OpenapiFirst::REQUEST].parsed_body).to eq request_body
    end

    it 'succeeds with multipart form data file binary upload' do
      uploaded_file = Rack::Test::UploadedFile.new(fixture_path('foo.txt'))

      post '/multipart-with-file', 'file' => uploaded_file
      expect(last_response.status).to eq(200)

      uploaded_file = last_request.env[OpenapiFirst::REQUEST].parsed_body['file']
      expect(uploaded_file).to eq File.read(fixture_path('foo.txt'))
    end

    it 'succeeds with nested multipart form data file binary upload' do
      uploaded_file = Rack::Test::UploadedFile.new(fixture_path('foo.txt'))

      post '/nested-multipart-with-file', 'user' => { 'avatar' => uploaded_file }
      expect(last_response.status).to eq(200), last_response.body

      uploaded_file = last_request.env[OpenapiFirst::REQUEST].parsed_body.dig('user', 'avatar')
      expect(uploaded_file).to eq File.read(fixture_path('foo.txt'))
    end

    it 'succeeds list of binary fields in multipart/form-data' do
      uploaded_file = Rack::Test::UploadedFile.new(fixture_path('foo.txt'))

      post '/users-with-avatars', 'data' => [{ 'avatar' => uploaded_file, 'name' => 'Quentin' }]
      expect(last_response.status).to eq(200), last_response.body

      names = last_request.env[OpenapiFirst::REQUEST].parsed_body.fetch('data').map { _1['name'] }
      expect(names).to eq(['Quentin'])
    end

    it 'succeeds with multipart form data with encoding specification' do
      csv_file = Rack::Test::UploadedFile.new(fixture_path('test.csv'), 'text/csv')
      json_data = { name: 'Test Product', description: 'A sample product' }

      post '/multipart-with-encoding', 
           'file' => csv_file,
           'data' => json_data.to_json

      expect(last_response.status).to eq(200), last_response.body

      parsed_body = last_request.env[OpenapiFirst::REQUEST].parsed_body
      expect(parsed_body['file']).to eq File.read(fixture_path('test.csv'))
      expect(parsed_body['data']).to eq(json_data.transform_keys(&:to_s))
    end

    it 'succeeds without optional file upload' do
      header Rack::CONTENT_TYPE,  'multipart/form-data'
      post '/multipart-with-file', 'petId' => '12'
      expect(last_response.status).to eq(200)

      expect(last_request.env[OpenapiFirst::REQUEST].parsed_body['petId']).to eq('12')
    end

    it 'supports text/plain content type' do
      header Rack::CONTENT_TYPE, 'text/plain'
      post path, 'Cat!'

      expect(last_response.status).to be(200), last_response.body
      expect(last_request.env[OpenapiFirst::REQUEST].parsed_body).to eq 'Cat!'
    end

    it 'works with % in request body' do
      request_body = {
        'type' => 'pet',
        'attributes' => {
          'name' => 'Oscar 100%'
        }
      }
      header Rack::CONTENT_TYPE, 'application/json'
      io = StringIO.new(JSON.generate(request_body))
      post path, io

      expect(last_response.status).to be 200
    end

    it 'succeeds if request body is valid' do
      header Rack::CONTENT_TYPE, 'application/json'
      post path, JSON.generate(request_body)

      expect(last_response.status).to be(200), last_response.body
    end

    it 'works with json:api media type' do
      header Rack::CONTENT_TYPE, 'application/vnd.api+json'
      post '/json_api', JSON.generate(request_body)

      expect(last_response.status).to be 200
      expect(last_request.env[OpenapiFirst::REQUEST].parsed_body).to eq request_body
    end

    it 'works with a custom json media type' do
      header Rack::CONTENT_TYPE, 'application/prs.custom-json-type+json'
      post '/custom-json-type', JSON.generate(request_body)

      expect(last_response.status).to be 200
      expect(last_request.env[OpenapiFirst::REQUEST].parsed_body).to eq request_body
    end

    it 'adds parsed request body to env' do
      header Rack::CONTENT_TYPE, 'application/json'
      post path, JSON.generate(request_body)

      expect(last_response.status).to be 200
      expect(last_request.env[OpenapiFirst::REQUEST].parsed_body).to eq request_body
    end

    it 'updates REQUEST_BODY' do
      header Rack::CONTENT_TYPE, 'application/json'
      post path, JSON.generate(request_body)

      expect(last_request.env[OpenapiFirst::REQUEST].parsed_body).to eq request_body
    end

    it 'returns 400 if request body is not valid' do
      request_body['attributes']['name'] = 43
      header Rack::CONTENT_TYPE, 'application/json'
      post path, JSON.generate(request_body)
      expect(last_response.status).to be 400
    end

    it 'returns 400 if required field is missing' do
      request_body['attributes'].delete('name')
      header Rack::CONTENT_TYPE, 'application/json'
      post path, JSON.generate(request_body)

      expect(last_response.status).to be 400
      expected_body = {
        'title' => 'Bad Request Body',
        'status' => 400,
        'errors' => [{
          'message' => 'object at `/attributes` is missing required properties: name',
          'pointer' => '/attributes',
          'code' => 'required'
        }]
      }
      expect(JSON.parse(last_response.body)).to eq(expected_body)
    end

    it 'returns 400 if value is not defined in enum' do
      request_body['type'] = 'unknown-type'
      header Rack::CONTENT_TYPE, 'application/json'
      post path, JSON.generate(request_body)

      expect(last_response.status).to be 400
    end

    it 'returns 400 if additional property is not allowed' do
      request_body['attributes'].update('foo' => :bar)
      header Rack::CONTENT_TYPE, 'application/json'
      post path, JSON.generate(request_body)

      expect(last_response.status).to be 400
    end

    it 'returns 400 if request body is invalid JSON' do
      header Rack::CONTENT_TYPE, 'application/json'
      post path, '{fo},'

      expect(last_response.status).to be 400
    end

    context 'when request body is optional' do
      let(:path) { '/optional-request-body' }

      it 'accepts a valid request body' do
        header Rack::CONTENT_TYPE, 'application/json'
        post path, JSON.generate({ say: 'yes' })

        expect(last_response.status).to be(200), last_response.body
        expect(last_request.env[OpenapiFirst::REQUEST].parsed_body).to eq 'say' => 'yes'
      end

      it 'accepts an empty request body' do
        header Rack::CONTENT_TYPE, 'application/json'
        post path

        expect(last_response.status).to be(200), last_response.body
        expect(last_request.env[OpenapiFirst::REQUEST].parsed_body).to eq nil
      end

      it 'accepts an empty request body without content-type' do
        post path

        expect(last_response.status).to be(200), last_response.body
        expect(last_request.env[OpenapiFirst::REQUEST].parsed_body).to eq nil
      end

      it 'accepts an unknown content-type and an empty request body' do
        header Rack::CONTENT_TYPE, 'foo/bar'
        post path

        expect(last_response.status).to be(200), last_response.body
        expect(last_request.env[OpenapiFirst::REQUEST].parsed_body).to eq nil
      end

      it 'returns 400 if content-type is unknown and request body is invalid' do
        header Rack::CONTENT_TYPE, 'foo/bar'
        post path, JSON.generate({ say: 'no ' })

        expect(last_response.status).to be(400), last_response.body
      end

      it 'returns 400 if request body is invalid' do
        header Rack::CONTENT_TYPE, 'application/json'
        post path, JSON.generate({ say: 'no ' })

        expect(last_response.status).to be(400), last_response.body
      end
    end

    context 'with default values' do
      before { header Rack::CONTENT_TYPE, 'application/json' }

      it 'adds the default value if value is missing' do
        params = {}
        post '/with-default-body-value', JSON.generate(params)
        expect(last_response.status).to eq(200)
        values = last_request.env[OpenapiFirst::REQUEST].parsed_body
        expect(values['has_default']).to eq true
      end

      it 'still validates the value' do
        params = {
          has_default: 'not-a-boolean'
        }
        post '/with-default-body-value', JSON.generate(params)
        expect(last_response.status).to eq(400)
      end

      it 'accepts the given value if value is given' do
        params = { has_default: false }
        post '/with-default-body-value', JSON.generate(params)
        expect(last_response.status).to eq(200)
        values = last_request.env[OpenapiFirst::REQUEST].parsed_body
        expect(values['has_default']).to eq false
      end
    end

    it 'ignores content type parameters' do
      header Rack::CONTENT_TYPE, 'application/json; encoding=utf-8'
      post '/pets', JSON.generate(request_body)

      expect(last_response.status).to be 200
    end

    it 'succeeds with form-urlencoded data' do
      header Rack::CONTENT_TYPE, 'application/x-www-form-urlencoded'
      post '/with-form-urlencoded', request_body

      expect(last_response.status).to be(200), last_response.body
      expect(last_request.env[OpenapiFirst::REQUEST].parsed_body).to eq request_body
    end

    it 'returns 400 if required request body is missing' do
      header Rack::CONTENT_TYPE, 'application/json'
      post path

      expect(last_response.status).to be 400
    end

    it 'returns 415 if request content-type does not match' do
      header Rack::CONTENT_TYPE, 'application/xml'
      post path, '<xml />'

      expect(last_response.status).to be 415
    end

    context 'when operation does not specify request body' do
      it 'passes with an empty request body' do
        post '/without-request-body'

        expect(last_response.status).to eq 200
        expect(last_response.body).to eq 'hello'
      end

      it 'ignores a given request body' do
        header Rack::CONTENT_TYPE, 'application/json'
        post '/without-request-body', request_body

        expect(last_response.status).to eq 200
        expect(last_response.body).to eq 'hello'
      end
    end

    context 'when request body is empty and not required' do
      it 'skips request body validation' do
        header Rack::CONTENT_TYPE, 'application/json'
        patch '/pets/1'

        expect(last_response.status).to eq(200), last_response.body
        expect(last_response.body).to eq 'hello'
      end
    end

    context 'with a required writeOnly field' do
      let(:app) do
        Rack::Builder.new do
          use OpenapiFirst::Middlewares::RequestValidation, spec: './spec/data/writeonly.yaml'
          run lambda { |_env|
            Rack::Response.new('hello', 201).finish
          }
        end
      end

      it 'returns 400 if field is missing' do
        header Rack::CONTENT_TYPE, 'application/json'
        post '/test', JSON.generate({ name: 'Gunda' })
        expect(last_response.status).to eq(400), last_response.body
      end

      it 'passes validation if field in request body is valid' do
        header Rack::CONTENT_TYPE, 'application/json'
        post '/test', JSON.generate({ name: 'Gunda', password: 'admin' })
        expect(last_response.status).to eq(201), last_response.body
      end
    end

    context 'with a readOnly required field' do
      let(:app) do
        Rack::Builder.new do
          use OpenapiFirst::Middlewares::RequestValidation, spec: './spec/data/readonly.yaml', raise_error: true
          run ->(_) {}
        end
      end

      it 'fails if request includes readOnly field' do
        header Rack::CONTENT_TYPE, 'application/json'
        request_body = {
          'name' => 'foo',
          'id' => '123'
        }
        expect do
          post '/test', JSON.generate(request_body)
        end.to raise_error OpenapiFirst::RequestInvalidError, 'Request body invalid: value at `/id` is `readOnly`'
      end
    end

    context 'with a required nullable field' do
      let(:app) do
        Rack::Builder.new do
          use OpenapiFirst::Middlewares::RequestValidation, spec: './spec/data/nullable.yaml', raise_error: true
          run lambda { |_env|
            Rack::Response.new('hello', 201).finish
          }
        end
      end

      it 'fails if field is missing' do
        header Rack::CONTENT_TYPE, 'application/json'
        expect do
          post '/test', JSON.generate({})
        end.to raise_error OpenapiFirst::RequestInvalidError, 'Request body invalid: ' \
                                                              'object at root is missing required properties: name'
      end

      it 'succeeds if field is nil' do
        header Rack::CONTENT_TYPE, 'application/json'
        request_body = {
          name: nil
        }
        post '/test', JSON.generate(request_body)
        expect(last_response.status).to eq 201
      end
    end

    describe 'raise_error: true' do
      let(:raise_error_option) { true }

      it 'raises error if request body is not valid' do
        request_body['attributes']['name'] = 43
        header Rack::CONTENT_TYPE, 'application/json'
        expect do
          post path, JSON.generate(request_body)
        end.to raise_error OpenapiFirst::RequestInvalidError, 'Request body invalid: ' \
                                                              'value at `/attributes/name` is not a string'
      end

      it 'raises error if required field is missing' do
        request_body['attributes'].delete('name')
        header Rack::CONTENT_TYPE, 'application/json'
        expect do
          post path, JSON.generate(request_body)
        end.to raise_error OpenapiFirst::RequestInvalidError, 'Request body invalid: object at `/attributes` ' \
                                                              'is missing required properties: name'
      end

      it 'raises error if request body is invalid JSON' do
        header Rack::CONTENT_TYPE, 'application/json'
        expect do
          post path, '{fo},'
        end.to raise_error OpenapiFirst::RequestInvalidError,
                           'Request body invalid: Failed to parse request body as JSON'
      end

      it 'raises error if request content-type does not match' do
        header Rack::CONTENT_TYPE, 'application/xml'
        expect do
          post path, '<xml />'
        end.to raise_error OpenapiFirst::RequestInvalidError,
                           %(Request content type is not defined. Content-Type application/xml is not defined. Content-Type should be application/json or multipart/form-data or text/plain.)
      end
    end
  end
end
