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

  spec.summary       = 'Implement REST APIs based on OpenApi 3.x'
  spec.homepage      = 'https://github.com/ahx/openapi_first'

  if spec.respond_to?(:metadata)
    spec.metadata['https://github.com/ahx/openapi_first'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/ahx/openapi_first'
    spec.metadata['changelog_uri'] = 'https://github.com/ahx/openapi_first/blob/main/CHANGELOG.md'
    spec.metadata['rubygems_mfa_required'] = 'true'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
          'public gem pushes.'
  end

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`
      .split("\x0")
      .reject { |f| f.match(%r{^(test|spec|features|benchmarks|examples|bin)/}) }
      .reject do |f|
      %w[Dockerfile Jenkinsfile .tool-versions CODEOWNERS .rspec .rubocop.yml .tool-versions
         Rakefile].include?(f)
    end
  end
  spec.bindir        = 'exe'
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.1.1'

  spec.add_runtime_dependency 'json_refs', '~> 0.1', '>= 0.1.7'
  spec.add_runtime_dependency 'json_schemer', '~> 2.0.0'
  spec.add_runtime_dependency 'multi_json', '~> 1.15'
  spec.add_runtime_dependency 'mustermann-contrib', '~> 3.0.0'
  spec.add_runtime_dependency 'openapi_parameters', '>= 0.3.1', '< 2.0'
  spec.add_runtime_dependency 'rack', '>= 2.2', '< 4.0'
end
