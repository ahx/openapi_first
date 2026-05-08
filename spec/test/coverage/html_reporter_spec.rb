# frozen_string_literal: true

RSpec.describe OpenapiFirst::Test::Coverage::HtmlReporter do
  let(:spec) do
    {
      'openapi' => '3.1.0',
      'paths' => {
        '/pets' => {
          'get' => {
            'responses' => {
              '200' => {
                'content' => {
                  'application/json' => { 'schema' => { 'type' => 'array', 'items' => { 'type' => 'object' } } }
                }
              },
              '400' => {
                'content' => {
                  'application/problem+json' => { 'schema' => { 'type' => 'object' } }
                }
              }
            }
          }
        }
      }
    }
  end

  let(:oad) { OpenapiFirst.parse(spec, filepath: 'myopenapi.yaml') }
  let(:plan) { OpenapiFirst::Test::Coverage::Plan.for(oad) }

  let(:valid_request) do
    rack_req = Rack::Request.new(Rack::MockRequest.env_for('/pets'))
    validated = oad.validate_request(rack_req)
    OpenapiFirst::Test::Coverage::CoveredRequest.new(key: validated.request_definition.key, error: validated.error)
  end

  let(:valid_200_response) do
    rack_req = Rack::Request.new(Rack::MockRequest.env_for('/pets'))
    rack_res = Rack::Response.new
    rack_res.content_type = 'application/json'
    rack_res.write JSON.generate([])
    validated = oad.validate_response(rack_req, rack_res)
    OpenapiFirst::Test::Coverage::CoveredResponse.new(key: validated.response_definition.key, error: validated.error)
  end

  def build_result(plan)
    plans = [plan]
    coverage = plans.sum(&:coverage) / plans.length.to_f
    OpenapiFirst::Test::Coverage::Result.new(plans:, coverage:)
  end

  def run_reporter(result, **opts)
    output_path = Tempfile.new(['api_coverage', '.html']).path
    logger = instance_double(Logger, info: nil, warn: nil)
    reporter = described_class.new(output: output_path, logger:, **opts)
    reporter.report(result)
    [File.read(output_path), logger]
  end

  context 'with uncovered requests and responses' do
    it 'marks uncovered requests in the summary' do
      result = build_result(plan)
      html, = run_reporter(result)
      expect(html).to include('request-status problem')
      expect(html).to include('/pets')
    end

    it 'does not mark anything as covered when nothing is covered' do
      result = build_result(plan)
      html, = run_reporter(result)
      expect(html).not_to include('class="covered"')
    end

    it 'shows the coverage percentage' do
      result = build_result(plan)
      html, = run_reporter(result)
      expect(html).to include('0.0%')
    end

    it 'logs the output path' do
      result = build_result(plan)
      output_path = Tempfile.new(['api_coverage', '.html']).path
      logger = instance_double(Logger, info: nil, warn: nil)
      described_class.new(output: output_path, logger:).report(result)
      expect(logger).to have_received(:info).with(include(output_path))
    end
  end

  context 'with fully covered requests and responses' do
    before do
      plan.track_request(valid_request)
      plan.track_response(valid_200_response)
    end

    it 'shows covered items with verbose: true' do
      plan_result = build_result(plan)
      html, = run_reporter(plan_result, verbose: true)
      expect(html).to include('class="covered"')
    end

    it 'shows all responses when some are uncovered (verbose: false)' do
      plan_result = build_result(plan)
      html, = run_reporter(plan_result)
      # 200 is covered but shown because 400 is still uncovered
      expect(html).to include('>200<')
      expect(html).to include('>400<')
      expect(html).to include('application/problem+json')
    end

    it 'signals in the summary that responses are uncovered' do
      plan_result = build_result(plan)
      html, = run_reporter(plan_result)
      expect(html).to include('response-summary problem')
      expect(html).to include('⚠️')
      expect(html).to include('1 response(s) not covered')
    end
  end

  context 'with no plans registered' do
    it 'writes a warning page' do
      result = OpenapiFirst::Test::Coverage::Result.new(plans: [], coverage: 0)
      html, = run_reporter(result)
      expect(html).to include('did not detect any API requests')
    end
  end
end
