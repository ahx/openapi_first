# OpenapiFirst

This helps developing Rack apps, starting with the [OpenApi Spec](https://www.openapis.org/) first.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openapi_first'
```

And then execute:

    $ bundle

## Usage

Start with writing an OpenAPI specification that describes the API, which you are about to write. Use a [validator](http://speccy.io/) to make sure the file is valid.

### Response validation

Response validation is to make sure your app responds as described in your OpenAPI spec. You usually to this in your tests using [rack-test](https://github.com/rack-test/rack-test).

```ruby
# In your test:
spec = OpenapiFirst.load('petstore.yaml')
validator = OpenapiFirst::ResponseValidator.new(spec)
validator.validate(last_request, last_response).errors? # => true or false
```

### Request validation (TODO)

```ruby
# In your app:
use OpenapiFirst::RequestValidator, spec: myspec
```

### Completeness / Test Coverage (TODO)

`OpenapiFirst::TestCoverage` can help you make sure, that you have called all endpoints of your OAS file when running tests via `rack-test`:

```ruby
# In your test (rspec example):
require 'openapi_first'

describe MyApp do
  include Rack::Test::Methods

  before(:all) do
    spec = OpenapiFirst.load('petstore.yaml')
    @app_wrapper = OpenapiFirst::TestCoverage.new(MyApp, spec)
  end

  after(:all) do
    message = "The following paths have not been called yet: #{@app_wrapper.to_be_called}"
    expect(@app_wrapper.to_be_called).to be_empty
  end

  # Overwrite `#app` to make rack-test call the wrapped app
  def app
    @app_wrapper
  end

  it 'does things' do
    get '/i/my/stuff'
    # …
  end
end
```

### Mocked server (TODO)

## Alternatives

This gem is inspired by [committee](https://github.com/interagent/committee), which has much more features like response stubs or support for Hyper-Schema or OpenAPI 2.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ivx/openapi_first.
