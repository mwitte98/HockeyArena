Rails.application.routes.draw do
  resources :users,        only: [:new,  :create, :update, :edit]
  resources :sessions,     only: [:new,  :create, :destroy]
  resources :players,      only: [:show, :destroy]
  resources :players do
    collection do
      delete 'destroy_multiple'
    end
  end
  root 'static_pages#home'
  match '/signup',      to: 'users#new',           via: 'get'
  match '/signin',      to: 'sessions#new',        via: 'get'
  match '/signout',     to: 'sessions#destroy',    via: 'delete'
  match '/players5758', to: 'players#show5758',    via: 'get'
  match '/players5960', to: 'players#show5960',    via: 'get'
  match '/get_info',    to: 'players#get_info',    via: 'get'
  match '/delete_all',  to: 'players#delete_all',  via: 'post', as: 'delete_all'
  # match '/get_NT_info', to: 'players#get_NT_info', via: 'post'
  # match '/login_HA',    to: 'players#login_HA',    via: 'get'
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
