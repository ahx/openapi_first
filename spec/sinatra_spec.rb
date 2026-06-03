# frozen_string_literal: true

require_relative 'spec_helper'
require 'json'
require 'rack/test'
require 'sinatra/base'
require 'openapi_first/sinatra'

RSpec.describe OpenapiFirst::Sinatra do
  include Rack::Test::Methods

  let(:petstore) { File.expand_path('data/petstore.yaml', __dir__) }

  let(:app) do
    petstore_path = petstore
    Class.new(Sinatra::Base) do
      set :environment, :test
      set :raise_errors, true
      set :show_exceptions, false
      register OpenapiFirst::Sinatra
      openapi petstore_path

      operation :listPets do
        content_type :json
        JSON.generate(parsed_params)
      end

      operation :showPetById do
        content_type :json
        JSON.generate(parsed_params)
      end

      operation :createPets do
        status 201
      end
    end
  end

  it 'routes a GET operation to its block and exposes parsed params' do
    get '/pets?limit=3'

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq('limit' => 3) # coerced to integer per the OAD
  end

  it 'derives the path (including path parameters) from the OpenAPI description' do
    get '/pets/42'

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq('petId' => '42')
  end

  it 'routes a POST operation to its block' do
    post '/pets'

    expect(last_response.status).to eq(201)
  end

  it 'returns 400 for a request that violates the contract (block not reached)' do
    get '/pets?limit=not-an-integer'

    expect(last_response.status).to eq(400)
  end

  it 'returns 404 for a path that is not in the OpenAPI description' do
    get '/unknown'

    expect(last_response.status).to eq(404)
  end

  it 'lets a plain Sinatra route alongside operations respond (routing is left to Sinatra)' do
    petstore_path = petstore
    klass = Class.new(Sinatra::Base) do
      set :environment, :test
      set :raise_errors, true
      set :show_exceptions, false
      register OpenapiFirst::Sinatra
      openapi petstore_path

      operation :listPets do
        content_type :json
        JSON.generate([])
      end
      get('/health') { 'ok' }
    end

    session = Rack::Test::Session.new(klass)

    session.get('/health')
    expect(session.last_response.status).to eq(200)
    expect(session.last_response.body).to eq('ok')

    session.get('/pets') # the operation route still works alongside the plain route
    expect(session.last_response.status).to eq(200)
    expect(session.last_response.body).to eq('[]')
  end

  it 'returns Sinatra\'s 404 for an undocumented method on a documented path' do
    delete '/pets/42' # showPetById defines GET, not DELETE

    expect(last_response.status).to eq(404)
  end

  it 'runs request validation hooks exactly once per request' do
    petstore_path = petstore
    calls = []
    definition = OpenapiFirst.load(petstore_path) do |config|
      config.before_request_validation { |_request, _definition| calls << :before }
      config.after_request_validation { |_validated, _definition| calls << :after }
    end
    klass = Class.new(Sinatra::Base) do
      set :environment, :test
      set :raise_errors, true
      set :show_exceptions, false
      register OpenapiFirst::Sinatra
      openapi definition

      operation :showPetById do
        content_type :json
        JSON.generate({})
      end
    end

    session = Rack::Test::Session.new(klass)
    session.get('/pets/42')

    expect(session.last_response.status).to eq(200)
    expect(calls).to eq(%i[before after])
  end

  it 'exposes the loaded definition via openapi_definition' do
    expect(app.openapi_definition).to be_a(OpenapiFirst::Definition)
  end

  context 'with the parsed_params helper' do
    let(:app) do
      petstore_path = petstore
      Class.new(Sinatra::Base) do
        set :environment, :test
        set :raise_errors, true
        set :show_exceptions, false
        register OpenapiFirst::Sinatra
        openapi petstore_path

        operation :listPets do
          content_type :json
          JSON.generate(
            symbol: parsed_params[:limit],   # coerced, symbol access
            string: parsed_params['limit'],  # coerced, string access
            raw: params['limit']             # Sinatra's native params, untouched
          )
        end
      end
    end

    it 'exposes coerced params with indifferent access and leaves Sinatra params raw' do
      get '/pets?limit=3'

      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body['symbol']).to eq(3)   # coerced to Integer per the OAD
      expect(body['string']).to eq(3)   # same value, string access
      expect(body['raw']).to eq('3')    # Sinatra's params keeps the original String
    end
  end

  context 'when the operation block declares an argument' do
    let(:app) do
      petstore_path = petstore
      Class.new(Sinatra::Base) do
        set :environment, :test
        set :raise_errors, true
        set :show_exceptions, false
        register OpenapiFirst::Sinatra
        openapi petstore_path

        operation :showPetById do |params|
          content_type :json
          JSON.generate(id: params[:petId]) # block receives the parsed params, not URL captures
        end
      end
    end

    it 'passes parsed_params to the block' do
      get '/pets/42'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq('id' => '42')
    end
  end

  it 'ignores operations without an operationId when indexing' do
    missing = File.expand_path('data/operation-id-missing.yaml', __dir__)
    klass = Class.new(Sinatra::Base) do
      register OpenapiFirst::Sinatra
      openapi missing
      # POST /pets has operationId `createPets`; GET /pets has none and is simply not addressable.
      operation :createPets do
        status 201
      end
    end

    session = Rack::Test::Session.new(klass)
    session.post('/pets')

    expect(session.last_response.status).to eq(201)
  end

  it 'lets a subclass inherit the loaded description and routing' do
    petstore_path = petstore
    parent = Class.new(Sinatra::Base) do
      set :environment, :test
      set :raise_errors, true
      set :show_exceptions, false
      register OpenapiFirst::Sinatra
      openapi petstore_path

      operation :listPets do
        content_type :json
        JSON.generate(parsed_params)
      end
    end
    child = Class.new(parent)

    session = Rack::Test::Session.new(child)
    session.get('/pets?limit=3')

    expect(session.last_response.status).to eq(200)
    expect(JSON.parse(session.last_response.body)).to eq('limit' => 3)
    expect(child.openapi_definition).to eq(parent.openapi_definition)
  end

  it 'raises if openapi is called twice for the same app' do
    petstore_path = petstore
    expect do
      Class.new(Sinatra::Base) do
        register OpenapiFirst::Sinatra
        openapi petstore_path
        openapi petstore_path
      end
    end.to raise_error(OpenapiFirst::Error, /once per app/)
  end

  it 'raises if operation is called before openapi' do
    expect do
      Class.new(Sinatra::Base) do
        register OpenapiFirst::Sinatra
        operation(:listPets) { 'never' }
      end
    end.to raise_error(OpenapiFirst::Error, /Call `openapi`/)
  end

  it 'raises if the operationId is not defined in the description, listing the defined operations' do
    petstore_path = petstore
    expect do
      Class.new(Sinatra::Base) do
        register OpenapiFirst::Sinatra
        openapi petstore_path
        operation(:doesNotExist) { 'never' }
      end
    end.to raise_error(ArgumentError, /doesNotExist.*Defined operationIds are: listPets, createPets, showPetById/m)
  end

  it 'suggests the closest operationId for a typo (Did you mean)' do
    petstore_path = petstore
    expect do
      Class.new(Sinatra::Base) do
        register OpenapiFirst::Sinatra
        openapi petstore_path
        operation(:listPet) { 'never' } # typo for listPets
      end
    end.to raise_error(ArgumentError, /Did you mean "listPets"\?/)
  end

  context 'with a JSON request body and an integer path parameter' do
    let(:body_spec) { File.expand_path('data/request-body-validation.yaml', __dir__) }

    let(:app) do
      spec_path = body_spec
      Class.new(Sinatra::Base) do
        set :environment, :test
        set :raise_errors, true
        set :show_exceptions, false
        register OpenapiFirst::Sinatra
        openapi spec_path

        operation :create_pet do
          content_type :json
          JSON.generate(parsed_body)
        end

        operation :update_pet do
          content_type :json
          id = parsed_params['id']
          JSON.generate('id' => id, 'id_class' => id.class.name)
        end
      end
    end

    it 'parses a JSON request body via openapi_request.parsed_body' do
      post '/pets', JSON.generate(type: 'pet', attributes: { name: 'Rex' }),
           'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq('type' => 'pet', 'attributes' => { 'name' => 'Rex' })
    end

    it 'returns 415 when the content type is not documented (block not reached)' do
      post '/pets', 'plain', 'CONTENT_TYPE' => 'application/xml'

      expect(last_response.status).to eq(415)
    end

    it 'returns 400 for an invalid body before the route runs' do
      post '/pets', JSON.generate(type: 'pet'), 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(400)
    end

    it 'coerces an integer path parameter per the OpenAPI description' do
      patch '/pets/42', JSON.generate(type: 'pet', attributes: { name: 'Rex' }),
            'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq('id' => 42, 'id_class' => 'Integer')
    end

    it 'returns 400 when an integer path parameter cannot be coerced' do
      patch '/pets/not-a-number', JSON.generate(type: 'pet', attributes: { name: 'Rex' }),
            'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(400)
    end
  end

  context 'with a top-level JSON array request body' do
    let(:app) do
      spec_path = File.expand_path('data/sinatra-array-body.yaml', __dir__)
      Class.new(Sinatra::Base) do
        set :environment, :test
        set :raise_errors, true
        set :show_exceptions, false
        register OpenapiFirst::Sinatra
        openapi spec_path

        operation :bulkCreatePets do
          content_type :json
          JSON.generate(parsed_body)
        end
      end
    end

    it 'returns the parsed array from parsed_body' do
      post '/bulk-pets', JSON.generate([{ name: 'Rex' }]), 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq([{ 'name' => 'Rex' }])
    end
  end

  it 'raises if the description uses the same operationId for different routes' do
    duplicate = File.expand_path('data/sinatra-duplicate-operation-id.yaml', __dir__)
    expect do
      Class.new(Sinatra::Base) do
        register OpenapiFirst::Sinatra
        openapi duplicate
      end
    end.to raise_error(OpenapiFirst::Error, /listThings/)
  end

  context 'with the operation_url helper' do
    let(:app) do
      petstore_path = petstore
      Class.new(Sinatra::Base) do
        set :environment, :test
        set :raise_errors, true
        set :show_exceptions, false
        register OpenapiFirst::Sinatra
        openapi petstore_path

        operation :listPets do
          content_type :text
          operation_url(:listPets)
        end

        operation :showPetById do
          content_type :text
          operation_url(:showPetById, 'petId' => params[:petId])
        end
      end
    end

    it 'returns the absolute URL for an operation without path parameters' do
      get '/pets'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('http://example.org/pets')
    end

    it 'fills in path parameters with string keys' do
      get '/pets/42'

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('http://example.org/pets/42')
    end

    it 'fills in path parameters with symbol keys' do
      petstore_path = petstore
      klass = Class.new(Sinatra::Base) do
        set :environment, :test
        set :raise_errors, true
        set :show_exceptions, false
        register OpenapiFirst::Sinatra
        openapi petstore_path

        operation :showPetById do
          content_type :text
          operation_url(:showPetById, petId: params[:petId])
        end
      end

      session = Rack::Test::Session.new(klass)
      session.get('/pets/42')

      expect(session.last_response.body).to eq('http://example.org/pets/42')
    end

    it 'raises ArgumentError for an unknown operationId' do
      petstore_path = petstore
      klass = Class.new(Sinatra::Base) do
        set :environment, :test
        set :raise_errors, true
        set :show_exceptions, false
        register OpenapiFirst::Sinatra
        openapi petstore_path

        operation :listPets do
          operation_url(:unknownOperation)
        end
      end

      session = Rack::Test::Session.new(klass)
      expect { session.get('/pets') }.to raise_error(ArgumentError, /unknownOperation/)
    end

    it 'raises ArgumentError when a required path parameter is missing' do
      petstore_path = petstore
      klass = Class.new(Sinatra::Base) do
        set :environment, :test
        set :raise_errors, true
        set :show_exceptions, false
        register OpenapiFirst::Sinatra
        openapi petstore_path

        operation :listPets do
          operation_url(:showPetById)
        end
      end

      session = Rack::Test::Session.new(klass)
      expect { session.get('/pets') }.to raise_error(ArgumentError, /petId/)
    end
  end

  context 'with multiple path parameters in a single path segment' do
    let(:range_spec) { File.expand_path('data/parameters-path.yaml', __dir__) }

    let(:app) do
      spec_path = range_spec
      Class.new(Sinatra::Base) do
        set :environment, :test
        set :raise_errors, true
        set :show_exceptions, false
        register OpenapiFirst::Sinatra
        openapi spec_path

        operation :info_date_range do
          content_type :json
          JSON.generate(openapi_request.parsed_path_parameters)
        end
      end
    end

    it 'routes /info/{start_date}..{end_date} and exposes both parameters' do
      get '/info/2020-01-01..2020-02-01'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq(
        'start_date' => '2020-01-01', 'end_date' => '2020-02-01'
      )
    end
  end

  context 'with a path parameter name containing a hyphen' do
    let(:hyphen_spec) { File.expand_path('data/sinatra-hyphen-param.yaml', __dir__) }

    let(:app) do
      spec_path = hyphen_spec
      Class.new(Sinatra::Base) do
        set :environment, :test
        set :raise_errors, true
        set :show_exceptions, false
        register OpenapiFirst::Sinatra
        openapi spec_path

        operation :showThing do
          content_type :json
          JSON.generate(openapi_request.parsed_path_parameters)
        end
      end
    end

    it 'routes /things/{thing-id} to its block and exposes the parameter under its real name' do
      get '/things/abc'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq('thing-id' => 'abc')
    end
  end
end
