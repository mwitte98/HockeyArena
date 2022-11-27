Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :users,        only: %i[new create update edit]
  resources :sessions,     only: %i[new create destroy]
  root 'static_pages#home'
  match '/signup', to: 'users#new', via: :get
  match '/signin', to: 'sessions#new', via: :get
  match '/signout', to: 'sessions#destroy', via: :delete
  match '/youth_school', to: 'youth_school#show', via: :get, as: 'ys'
  match '/youth_school', to: 'youth_school#update', via: :put
  match '*path', to: 'static_pages#home', via: :get
end
