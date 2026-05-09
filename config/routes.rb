Rails.application.routes.draw do
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check

  root "players#index"

  resources :players

  resources :games do
    member do
      get :setup_teams
      post :save_teams
    end
    resources :rounds, only: [:create, :destroy]
  end

  resources :teams, only: [] do
    resources :team_players, only: [:create, :destroy]
  end

  resources :tournaments do
    get :statistics, on: :member, to: "statistics#tournament"
  end

  resources :tournament_series do
    get :statistics, on: :member, to: "statistics#serie"
  end

  get "statistics", to: "statistics#index"
end
