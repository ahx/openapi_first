# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RuboCop::RakeTask.new

task :version do
  puts Gem::Specification.load('openapi_first.gemspec').version
end

RSpec::Core::RakeTask.new(:spec)

task default: %i[spec rubocop]
