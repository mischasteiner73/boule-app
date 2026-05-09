Rails.application.routes.draw do
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

  get "statistics", to: "statistics#index"
  get "tournaments/:id/statistics", to: "statistics#tournament", as: :tournament_statistics
end
