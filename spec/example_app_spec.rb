require 'rack/test'
require_relative 'spec_helper'
require_relative '../examples/app'

RSpec.describe 'Example App' do
  include Rack::Test::Methods

  def app
    App
  end

  it 'does not explode' do
    get '/'
    expect(last_response.body).to eq 'Hello'
  end
end
