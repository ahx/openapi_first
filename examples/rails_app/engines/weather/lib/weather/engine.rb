module Weather
  class Engine < ::Rails::Engine
    isolate_namespace Weather
    config.generators.api_only = true
  end
end
