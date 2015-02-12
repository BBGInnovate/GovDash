Radd::Application.routes.draw do
  namespace :admin do
    resources :accounts do
      as_routes
      collection do
        # get 'start_producers'
        # get 'stop_producers'
        get 'start_consumer'
        et 'stop_consumer'
      end
    end
  end
end