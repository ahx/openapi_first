# frozen_string_literal: true

RSpec.describe 'Hooks' do
  def build_request(path, method: 'GET', body: nil)
    Rack::Request.new(Rack::MockRequest.env_for(path, method:, input: body, 'CONTENT_TYPE' => 'application/json'))
  end

  describe 'adding a hook' do
    specify do
      called = []
      myproc = proc do |request|
        called << [request.operation_id, request.valid?]
      end

      definition = OpenapiFirst.load('./spec/data/petstore.yaml') do |config|
        config.after_request_validation(&myproc)
      end
      definition.validate_request(build_request('/pets?limit=24'))

      expect(called).to eq([['listPets', true]])
    end
  end

  describe 'after_request_validation' do
    let(:called) { [] }
    let(:definition) do
      OpenapiFirst.load('./spec/data/petstore.yaml') do |config|
        config.after_request_validation do |request|
          called << [request.operation_id, request.valid?]
        end
      end
    end

    it 'calls the hook' do
      definition.validate_request(build_request('/pets?limit=24'))

      expect(called).to eq([['listPets', true]])
    end

    it 'calls the hook with an invalid request' do
      definition.validate_request(build_request('/pets?limit=fourtytwo'))

      expect(called).to eq([['listPets', false]])
    end

    it 'can pass the doc as a second argument' do
      definition = OpenapiFirst.load('./spec/data/petstore.yaml') do |config|
        config.after_request_validation do |request, doc|
          called << [request.path, doc]
        end
      end
      definition.validate_request(build_request('/pets'))
      expect(called).to eq([['/pets', definition]])
    end
  end

  describe 'after_response_validation' do
    let(:called) { [] }

    let(:definition) do
      OpenapiFirst.load('./spec/data/petstore.yaml') do |config|
        config.after_response_validation do |response|
          called << response.valid?
        end
      end
    end

    it 'calls the hook' do
      response = Rack::Response.new('[]', 200, { 'Content-Type' => 'application/json' })
      definition.validate_response(build_request('/pets/42'), response)

      expect(called).to eq([true])
    end

    it 'calls the hook with an invalid response' do
      response = Rack::Response.new('{"foo": "bar"}', 200, { 'Content-Type' => 'application/json' })
      definition.validate_response(build_request('/pets/42'), response)

      expect(called).to eq([false])
    end

    it 'can pass the request and doc as arguments' do
      definition = OpenapiFirst.load('./spec/data/petstore.yaml') do |config|
        config.after_response_validation do |response, request, doc|
          called << [response.status, request.path, doc]
        end
      end
      response = Rack::Response.new('{"foo": "bar"}', 200, { 'Content-Type' => 'application/json' })
      definition.validate_response(build_request('/pets'), response)
      expect(called).to eq([[200, '/pets', definition]])
    end
  end

  describe 'after_request_parameter_property_validation' do
    let(:called) { [] }

    let(:spec) do
      {
        'openapi' => '3.1.0',
        'paths' => {
          '/{color}' => {
            'parameters' => [
              {
                'name' => 'color',
                'in' => 'path',
                'schema' => {
                  'type' => 'string'
                }
              }
            ],
            'post' => {
              'parameters' => [
                {
                  'name' => 'page',
                  'in' => 'query',
                  'schema' => {
                    'type' => 'integer'
                  }
                }
              ],
              'requestBody' => {
                'content' => {
                  'application/json' => {
                    'schema' => {
                      'type' => 'object',
                      'properties' => {
                        'name' => {
                          'type' => 'string'
                        }
                      }
                    }
                  }
                }
              },
              'responses' => {
                '200' => {
                  'description' => 'ok'
                }
              }
            }
          }
        }
      }
    end

    it 'calls the hook' do
      definition = OpenapiFirst.parse(spec) do |config|
        config.after_request_parameter_property_validation do |data, property, property_schema|
          called << [data, property, property_schema]
        end
      end

      definition.validate_request(build_request('/blue?page=2', method: 'POST', body: '{"name": "Quentin"}'))

      expect(called).to eq([
                             [{ 'color' => 'blue' }, 'color', {
                               'type' => 'string'
                             }],
                             [{ 'page' => 2 }, 'page', {
                               'type' => 'integer'
                             }]
                           ])
    end

    it 'can modify the returned parameters' do
      definition = OpenapiFirst.parse(spec) do |config|
        config.after_request_parameter_property_validation do |data, property, _property_schema|
          data[property] = 'two' if property == 'page'
        end
      end
      validated = definition.validate_request(build_request('/blue?page=2', method: 'POST', body: '{"name": "Quentin"}'))
      expect(validated.parsed_query['page']).to eq('two')
      expect(validated).to be_valid
    end
  end

  describe 'after_request_body_property_validation' do
    let(:called) { [] }

    it 'calls the hook' do
      spec = {
        'openapi' => '3.1.0',
        'paths' => {
          '/{color}' => {
            'parameters' => [
              {
                'name' => 'color',
                'in' => 'path',
                'schema' => {
                  'type' => 'string'
                }
              }
            ],
            'post' => {
              'requestBody' => {
                'content' => {
                  'application/json' => {
                    'schema' => {
                      'type' => 'object',
                      'properties' => {
                        'name' => {
                          'type' => 'string'
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      definition = OpenapiFirst.parse(spec) do |config|
        config.after_request_body_property_validation do |data, property, property_schema|
          called << [data, property, property_schema]
        end
      end

      request = build_request('/blue?page=2', method: 'POST', body: '{"name": "Quentin"}')
      validated = definition.validate_request(request)

      expect(validated).to be_valid
      expect(called).to eq([
                             [{ 'name' => 'Quentin' }, 'name', { 'type' => 'string' }]
                           ])
    end
  end

  describe 'after_response_body_property_validation' do
    let(:called) { [] }

    it 'calls the hook' do
      spec = {
        'openapi' => '3.1.0',
        'paths' => {
          '/{color}' => {
            'parameters' => [
              {
                'name' => 'color',
                'in' => 'path',
                'schema' => {
                  'type' => 'string'
                }
              }
            ],
            'post' => {
              'requestBody' => {
                'content' => {
                  'application/json' => {
                    'schema' => {
                      'type' => 'object',
                      'properties' => {
                        'name' => {
                          'type' => 'string'
                        }
                      }
                    }
                  }
                }
              },
              'responses' => {
                '200' => {
                  'description' => 'ok',
                  'content' => {
                    'application/json' => {
                      'schema' => {
                        'type' => 'object',
                        'properties' => {
                          'foo' => {
                            'type' => 'string'
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      definition = OpenapiFirst.parse(spec) do |config|
        config.after_response_body_property_validation do |data, property, property_schema|
          called << [data, property, property_schema]
        end
      end

      request = build_request('/blue?page=2', method: 'POST', body: '{"name": "Quentin"}')
      response = Rack::Response.new('{"foo": "bar"}', 200, { 'Content-Type' => 'application/json' })
      validated = definition.validate_response(request, response)

      expect(validated).to be_valid
      expect(called).to eq([
                             [{ 'foo' => 'bar' }, 'foo', { 'type' => 'string' }]
                           ])
    end
  end
end
