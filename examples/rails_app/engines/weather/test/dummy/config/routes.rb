Rails.application.routes.draw do
  mount Weather::Engine => "/weather"
end
