# frozen_string_literal: true

RSpec.describe OpenapiFirst::Test::Coverage::Plan do
  let(:spec) do
    {
      'openapi' => '3.1.0',
      'paths' => {
        '/stuff/{id}' => {
          'parameters' => [
            {
              'name' => 'id',
              'in' => 'path',
              'required' => true,
              'schema' => {
                'type' => 'integer'
              }
            }
          ],
          'get' => {
            'responses' => {
              '200' => {
                'content' => {
                  'application/json' => {
                    'schema' => {
                      'type' => 'object'
                    }
                  }
                }
              },
              '4XX' => {
                'content' => {
                  'application/json' => {
                    'schema' => {
                      'type' => 'object'
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  end

  let(:oad) { OpenapiFirst.parse(spec, filepath: 'myopenapi.yaml') }

  let(:valid_request) do
    request = Rack::Request.new(Rack::MockRequest.env_for('/stuff/24'))
    oad.validate_request(request)
  end

  let(:invalid_request) do
    request = Rack::Request.new(Rack::MockRequest.env_for('/stuff/2t4'))
    oad.validate_request(request)
  end

  let(:valid_response) do
    request = Rack::Request.new(Rack::MockRequest.env_for('/stuff/24'))
    response = Rack::Response.new
    response.content_type = 'application/json'
    response.write JSON.generate({})
    oad.validate_response(request, response)
  end

  let(:invalid_response) do
    request = Rack::Request.new(Rack::MockRequest.env_for('/stuff/24'))
    response = Rack::Response.new
    response.content_type = 'application/json'
    response.write JSON.generate('foo')
    oad.validate_response(request, response)
  end

  let(:valid_400_response) do
    request = Rack::Request.new(Rack::MockRequest.env_for('/stuff/24'))
    response = Rack::Response.new
    response.status = 400
    response.content_type = 'application/json'
    response.write JSON.generate({})
    oad.validate_response(request, response)
  end

  subject(:plan) { described_class.for(oad) }

  it 'tracks requests and responses' do
    request = plan.routes.first.requests.first
    expect(request.requested?).to be(false)

    plan.track_request(valid_request)

    expect(request.requested?).to be(true)

    response = plan.routes.first.responses.first
    expect(response.responded?).to be(false)

    plan.track_response(valid_response)

    expect(response.responded?).to be(true)
  end

  it 'stores details about invalid responses' do
    plan.track_response(invalid_response)

    response = plan.routes.first.responses.first
    expect(response.responded?).to eq(true)
    expect(response.any_valid_response?).to eq(false)
    expect(response.last_error_message).to eq('Response body is invalid: value at root is not an object')
  end

  it 'stores details about invalid requests' do
    plan.track_request(invalid_request)

    request = plan.routes.first.requests.first
    expect(request.requested?).to eq(true)
    expect(request.any_valid_request?).to eq(false)
    expect(request.last_error_message).to eq('Path segment is invalid: value at `/id` is not an integer')
  end

  it 'ignores unknown requests' do
    request = Rack::Request.new(Rack::MockRequest.env_for('/unknown/24'))
    plan.track_request(oad.validate_request(request))
    expect(plan.coverage).to eq(0)
  end

  it 'ignores unknown responses' do
    request = Rack::Request.new(Rack::MockRequest.env_for('/stuff/24'))
    response = Rack::Response.new
    response.status = 309
    plan.track_response(oad.validate_response(request, response))
    expect(plan.coverage).to eq(0)
  end

  it 'returns coverage in percentage' do
    expect(plan.coverage).to eq(0)

    plan.track_request(valid_request)
    plan.track_response(valid_response)
    expect(plan.coverage).to eq(66.66666666666667)
    plan.track_response(valid_400_response)

    expect(plan.coverage).to eq(100)
  end

  it 'can be done' do
    expect(plan).not_to be_done

    plan.track_request(valid_request)
    plan.track_response(valid_response)
    plan.track_response(valid_400_response)

    expect(plan).to be_done
  end

  it 'has tasks, finished and unfinished' do
    expect(plan.tasks.count).to eq(3)

    expect(plan.tasks.count(&:finished?)).to eq(0)

    plan.track_request(valid_request)
    plan.track_response(valid_response)
    plan.track_response(valid_400_response)

    expect(plan.tasks.count(&:finished?)).to eq(3)
  end

  it 'has ordered tasks' do
    expect(plan.tasks[0].path).to eq('/stuff/{id}')
    expect(plan.tasks[1].status).to eq('200')
    expect(plan.tasks[2].status).to eq('4XX')
  end

  it 'ignores unknown responses' do
    request = Rack::Request.new(Rack::MockRequest.env_for('/stuff/24'))
    response = Rack::Response.new
    response.status = 208
    unknown_response = oad.validate_response(request, response)

    plan.track_response(unknown_response)

    expect(plan.tasks.count(&:finished?)).to eq(0)
  end

  it 'ignores skipped responses' do
    plan = described_class.for(oad, skip_response: ->(res) { res.status == '200' })

    plan.track_response(valid_response)

    expect(plan.tasks.count(&:finished?)).to eq(0)
  end

  context 'with skip_response option' do
    let(:plan) do
      skip_response = ->(response) { response.status == '4XX' }
      described_class.for(oad, skip_response:)
    end

    it 'can be done without the skipped response' do
      expect(plan).not_to be_done

      plan.track_request(valid_request)
      plan.track_response(valid_response)

      expect(plan.coverage).to eq(100)
    end
  end
end
