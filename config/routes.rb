Rails.application.routes.draw do
  resources :users,        only: [:new,  :create, :update, :edit]
  resources :sessions,     only: [:new,  :create, :destroy]
  resources :players,      only: [:show]
  resources :players do
    collection do
      delete 'destroy_multiple'
    end
  end
  root 'static_pages#home'
  match '/signup',          to: 'users#new',           via: 'get'
  match '/signin',          to: 'sessions#new',        via: 'get'
  match '/signout',         to: 'sessions#destroy',    via: 'delete'
  match '/players6566',     to: 'players#show6566',    via: 'get'
  match '/players6768',     to: 'players#show6768',    via: 'get'
  match '/playersSenior',   to: 'players#show_senior', via: 'get'
  match '/update_info',     to: 'players#update_info', via: 'get'
  match '/delete_all',      to: 'players#delete_all',  via: 'post', as: 'delete_all'
  match '/speedoBetaDraft', to: 'youth_school#speedo_beta_draft', via: 'get'
  match '/speedoBetaYS',    to: 'youth_school#speedo_beta_ys',    via: 'get'
  match '/speedoLiveDraft', to: 'youth_school#speedo_live_draft', via: 'get'
  match '/speedoLiveYS',    to: 'youth_school#speedo_live_ys',    via: 'get'
  match '/speedyBetaDraft', to: 'youth_school#speedy_beta_draft', via: 'get'
  match '/speedyBetaYS',    to: 'youth_school#speedy_beta_ys',    via: 'get'
  match '/speedyLiveDraft', to: 'youth_school#speedy_live_draft', via: 'get'
  match '/speedyLiveYS',    to: 'youth_school#speedy_live_ys',    via: 'get'
end
