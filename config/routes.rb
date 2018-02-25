Rails.application.routes.draw do
  resources :users,        only: %i[new create update edit]
  resources :sessions,     only: %i[new create destroy]
  resources :players,      only: [:show]
  resources :players do
    collection do
      delete 'destroy_multiple'
    end
  end
  root 'static_pages#home'
  match '/signup', to: 'users#new', via: :get
  match '/signin', to: 'sessions#new', via: :get
  match '/signout', to: 'sessions#destroy', via: :delete
  match '/national/:team', to: 'players#show_national_team', via: :get, as: 'national'
  match '/update_info', to: 'players#update_info', via: :get
  match '/delete_all', to: 'players#delete_all', via: :post, as: 'delete_all'
  match '/youth_school', to: 'youth_school#show', via: :get, as: 'ys'
  match '*path', to: 'static_pages#home', via: :get
end
