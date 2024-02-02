# frozen_string_literal: true

require_relative 'lib/openapi_first/version'

Gem::Specification.new do |spec|
  spec.name          = 'openapi_first'
  spec.version       = OpenapiFirst::VERSION
  spec.authors       = ['Andreas Haller']
  spec.email         = ['andreas.haller@posteo.de']
  spec.licenses      = ['MIT']

  spec.summary       = 'Implement HTTP APIs based on OpenApi 3.x'
  spec.homepage      = 'https://github.com/ahx/openapi_first'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['documentation_uri'] = 'https://www.rubydoc.info/gems/openapi_first/'
  spec.metadata['source_code_uri'] = 'https://github.com/ahx/openapi_first'
  spec.metadata['changelog_uri'] = 'https://github.com/ahx/openapi_first/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['{lib}/**/*.rb', 'LICENSE.txt', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.1.1'

  spec.add_runtime_dependency 'hana', '~> 1.3'
  spec.add_runtime_dependency 'json_schemer', '~> 2.1.0'
  spec.add_runtime_dependency 'multi_json', '~> 1.15'
  spec.add_runtime_dependency 'mustermann', '~> 3.0.0'
  spec.add_runtime_dependency 'openapi_parameters', '>= 0.3.2', '< 2.0'
  spec.add_runtime_dependency 'rack', '>= 2.2', '< 4.0'
end
