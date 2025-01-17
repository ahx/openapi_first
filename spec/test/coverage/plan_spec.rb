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

  let(:valid_response) do
    request = Rack::Request.new(Rack::MockRequest.env_for('/stuff/24'))
    response = Rack::Response.new
    response.content_type = 'application/json'
    response.write JSON.generate({})
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

  subject(:plan) { described_class.new(oad) }

  it 'has requests and responses' do
    request = plan.requests.first
    expect(request.requested?).to be(false)
    expect(request.path).to eq('/stuff/{id}')
    expect(request.request_method).to eq('get')
    expect(request.content_type).to eq(nil)

    response = request.responses.first
    expect(response.responded?).to be(false)
    expect(response.status).to eq('200')
    expect(response.content_type).to eq('application/json')
  end

  it 'tracks requests and responses' do
    request = plan.requests.first
    expect(request.requested?).to be(false)

    plan.track_request(valid_request)

    expect(request.requested?).to be(true)

    response = request.responses.first
    expect(response.responded?).to be(false)

    plan.track_response(valid_response)

    expect(response.responded?).to be(true)
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
    expect(plan.coverage).to eq(66)
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
    expect(plan.tasks.count(&:request?)).to eq(1)
    expect(plan.tasks.count(&:response?)).to eq(2)

    expect(plan.tasks.count(&:finished?)).to eq(0)
    expect(plan.tasks.count(&:unfinished?)).to eq(3)

    plan.track_request(valid_request)
    plan.track_response(valid_response)
    plan.track_response(valid_400_response)

    expect(plan.tasks.count(&:finished?)).to eq(3)
    expect(plan.tasks.count(&:unfinished?)).to eq(0)
  end

  it 'has ordered tasks' do
    expect(plan.tasks[0]).to be_request
    expect(plan.tasks[0].path).to eq('/stuff/{id}')
    expect(plan.tasks[1]).to be_response
    expect(plan.tasks[1].status).to eq('200')
    expect(plan.tasks[2]).to be_response
    expect(plan.tasks[2].status).to eq('4XX')
  end
end
