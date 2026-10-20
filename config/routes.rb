Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  devise_for :users, only: :sessions
  resources :journal_entries
  resources :enrollments, only: %i[index create destroy]
  root "home#index"
  get "provider", to: "providers#show", as: :provider_home
  get "client", to: "clients#show", as: :client_home
end
