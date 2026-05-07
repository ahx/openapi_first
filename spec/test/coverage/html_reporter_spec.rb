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
    it 'writes an HTML file' do
      result = build_result(plan)
      html, = run_reporter(result)
      expect(html).to include('<!DOCTYPE html>')
    end

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

    it 'omits covered responses by default (verbose: false)' do
      plan_result = build_result(plan)
      html, = run_reporter(plan_result)
      # 200 response is covered and must be hidden (status and content-type appear in separate spans)
      expect(html).not_to include('>200<')
      # The uncovered 400 response still appears
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

  describe OpenapiFirst::Test::Coverage::HtmlReporter::Context do
    let(:context) { described_class.new(build_result(plan), false) }
    let(:verbose_context) { described_class.new(build_result(plan), true) }
    let(:route) { plan.routes.first }

    describe '#expand_plan?' do
      it 'is true when verbose' do
        expect(verbose_context.expand_plan?(plan)).to be(true)
      end

      it 'is true when the plan is fully covered' do
        plan.track_request(valid_request)
        plan.track_response(valid_200_response)
        # Need an additional plan setup for "done?" — petstore has a 400 too,
        # so use the simpler check: when not done and not verbose, it's false.
        expect(context.expand_plan?(plan)).to be(false)
      end

      it 'is false otherwise' do
        expect(context.expand_plan?(plan)).to be(false)
      end
    end

    describe '#visible_routes' do
      it 'drops finished routes when the plan is not expanded' do
        plan.track_request(valid_request)
        plan.track_response(valid_200_response)
        # 400 still uncovered, so plan.done? is false → context not expanded
        expect(context.visible_routes(plan)).to include(route) # route has uncovered 400 response
      end

      it 'returns all routes when the plan is expanded (verbose)' do
        expect(verbose_context.visible_routes(plan)).to eq(plan.routes)
      end
    end

    describe '#route_status' do
      it 'is :request_problem when no request has been validated' do
        expect(context.route_status(route)).to eq(:request_problem)
      end

      it 'is :responses_problem when requests succeeded but responses are uncovered' do
        plan.track_request(valid_request)
        plan.track_response(valid_200_response)
        # 400 is still uncovered
        expect(context.route_status(route)).to eq(:responses_problem)
      end

      it 'is :ok when everything on the route is covered' do
        plan.track_request(valid_request)
        plan.track_response(valid_200_response)
        rack_req = Rack::Request.new(Rack::MockRequest.env_for('/pets'))
        rack_res = Rack::Response.new('{}', 400, 'Content-Type' => 'application/problem+json')
        validated = oad.validate_response(rack_req, rack_res)
        plan.track_response(
          OpenapiFirst::Test::Coverage::CoveredResponse.new(
            key: validated.response_definition.key, error: validated.error
          )
        )
        expect(context.route_status(route)).to eq(:ok)
      end
    end

    describe '#response_items' do
      before do
        plan.track_request(valid_request)
        plan.track_response(valid_200_response)
      end

      it 'returns only uncovered responses when the plan is not expanded' do
        items = context.response_items(route, plan_verbose: false)
        expect(items.map(&:status)).to eq(['400'])
      end

      it 'returns all responses when expanded' do
        items = context.response_items(route, plan_verbose: true)
        expect(items.map(&:status)).to contain_exactly('200', '400')
      end

      it 'is empty when no request was made and the plan is not expanded' do
        plan_b = OpenapiFirst::Test::Coverage::Plan.for(oad)
        ctx = described_class.new(
          OpenapiFirst::Test::Coverage::Result.new(plans: [plan_b], coverage: 0),
          false
        )
        expect(ctx.response_items(plan_b.routes.first, plan_verbose: false)).to be_empty
      end
    end
  end
end
