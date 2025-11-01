require_relative "lib/weather/version"

Gem::Specification.new do |spec|
  spec.name        = "weather"
  spec.version     = Weather::VERSION
  spec.authors     = [ "Joshua Studt" ]
  spec.email       = [ "fake.email@example.com" ]
  spec.homepage    = "http://mygemserver.com"
  spec.summary     = "Summary of Weather."
  spec.description = "Description of Weather."

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "http://mygemserver.com"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.2.2.1"
end
