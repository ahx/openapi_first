Weather::Engine.routes.draw do
  get "temperature", to: "temperature#index"
end
