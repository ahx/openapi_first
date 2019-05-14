# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'openapi_first/version'

Gem::Specification.new do |spec|
  spec.name          = 'openapi_first'
  spec.version       = OpenapiFirst::VERSION
  spec.authors       = ['Andreas Haller']
  spec.email         = ['andreas.haller@invision.de']

  spec.summary       = 'Tools to help developing APIs, OpenAPI spec first.'
  spec.homepage      = 'https://github.com/ivx/openapi_first'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['https://github.com/ivx/openapi_first'] = spec.homepage
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`
      .split("\x0")
      .reject { |f| f.match(%r{^(test|spec|features)/}) }
      .reject { |f| %w[Dockerfile Jenkinsfile].include?(f) }
  end
  spec.bindir        = 'exe'
  spec.require_paths = ['lib']

  spec.add_dependency 'json_schemer', '~> 0.2'
  spec.add_dependency 'multi_json', '~> 1.13'
  spec.add_dependency 'oas_parser', '~> 0.18'
  spec.add_dependency 'rack', '~> 2'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rack-test', '~> 1'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
