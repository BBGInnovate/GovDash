Radd::Application.routes.draw do
  resources :home, only: [:index]
  root :to => "home#index"
  devise_for :users
  
  resource :facebook, :except => :create do
    get :callback, :to => :create
  end
  
  resource :facebooks, :only=>:index do
    collection do
      get 'index'
    end
  end
  
  namespace :admin do
    resources :accounts do
      as_routes
      collection do
        get 'start_producers'
        get 'stop_producers'
        get 'start_consumer'
        get 'stop_consumer'
      end
    end
  end
end
