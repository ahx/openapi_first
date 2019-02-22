require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

task :version do
  puts Gem::Specification.load('openapi_first.gemspec').version
end

RSpec::Core::RakeTask.new(:spec)

task default: :spec
