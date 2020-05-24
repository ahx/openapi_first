# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'openapi_first/version'

Gem::Specification.new do |spec|
  spec.name          = 'openapi_first'
  spec.version       = OpenapiFirst::VERSION
  spec.authors       = ['Andreas Haller']
  spec.email         = ['andreas.haller@posteo.de']
  spec.licenses      = ['MIT']

  spec.summary       = 'Implement REST APIs based on OpenApi.'
  spec.homepage      = 'https://github.com/ahx/openapi_first'

  if spec.respond_to?(:metadata)
    spec.metadata['https://github.com/ahx/openapi_first'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/ahx/openapi_first'
    spec.metadata['changelog_uri'] = 'https://github.com/ahx/openapi_first/blob/master/CHANGELOG.md'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`
      .split("\x0")
      .reject { |f| f.match(%r{^(test|spec|features)/}) }
      .reject { |f| %w[Dockerfile Jenkinsfile .tool-versions].include?(f) }
  end
  spec.bindir        = 'exe'
  spec.require_paths = ['lib']

  spec.add_dependency 'deep_merge', '>= 1.2.1'
  spec.add_dependency 'hanami-router', '~> 2.0.alpha3'
  spec.add_dependency 'hanami-utils', '~> 2.0.alpha1'
  spec.add_dependency 'json_schemer', '~> 0.2'
  spec.add_dependency 'multi_json', '~> 1.14'
  spec.add_dependency 'oas_parser', '~> 0.25.1'
  spec.add_dependency 'rack', '~> 2.2'

  spec.add_development_dependency 'bundler', '~> 2'
  spec.add_development_dependency 'rack-test', '~> 1'
  spec.add_development_dependency 'rake', '~> 13'
  spec.add_development_dependency 'rspec', '~> 3'
end
