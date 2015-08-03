Radd::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products
  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'
  
  # http://guides.rubyonrails.org/routing.html#nested-resources
  # class Magazine < ActiveRecord::Base
  #   has_many :ads
  #  end
 
  #class Ad < ActiveRecord::Base
  #   belongs_to :magazine
  # end
  # resources :magazines do
  #   resources :ads
  #  end
  #  /magazines/:magazine_id/ads   ads#index
  #  display a list of all ads for a specific magazine

  resources :home, only: [:index]
  root :to => "home#index"
  devise_for :users

  # Connect Site
=begin
  resource :facebook, :except => :create do
    get :callback, action: :create
  end
  
  resource :facebooks, :only=>:index do
    collection do
      get 'index'
    end
  end

  resource :twitter, :except => :create do
    get :callback, action: :create
  end
  resource :twitters, :only=>:index do
    collection do
      get 'index'
    end
  end
=end

  namespace :api, defaults: {format: :json} do
    scope module: :v2, constraints: ApiConstraints.new(version: 1, default: :true) do

      devise_scope :user do
        match '/sessions' => 'sessions#create', :via => :post
        match '/sessions' => 'sessions#destroy', :via => :delete
      end

      # 3/18/15 match '/facebook/*path' => "facebooks#index", via: [:get]
      # 3/18/15 match '/twitter/*path' => "twitters#index", via: [:get]
      match '/reports' => "reports#index", via: [:get,:post]
      # 3/18/15 match '/sitecatalyst/*path' => "sitecatalyst#index", via: [:get]
      
      resources :record do
        collection do
          get 'roles'
        end
      end

      resources :accounts do
        collection do
          get 'countries'
          get 'users'
          get 'lookups'
          get 'segments'
        end
      end
      resources :organizations
      resources :groups
      resources :subgroups
      resources :regions
      resources :countries
      resources :sc_segments, :path => "segments"
      resources :languages
      resources :media_types
      # resources :account_types, :only=>:index
      resources :accounts_countries
      resources :accounts_sc_segments, :path => "accounts_segments"
      resources :accounts_regions
      resources :accounts_users
      resources :accounts_groups
      resources :accounts_subgroups
      resources :subroles, :only=>:index
      resources :users do
        collection do
          get 'roles'
          get 'confirm'
        end
      end
      
      # 3/18/15  resources :facebooks, :only=>:index
      
      # match '/users' => 'users#show', :via => :get 
      # match '/users' => 'users#update', :via => :put
      # match '/users' => 'users#destroy', :via => :delete
    end
  end

  namespace :admin do
    resources :error_logs do
      as_routes
      collection do
        get 'fetch'
      end
    end
=begin 
    3/18/15 
    resources :fb_pages do
      as_routes
    end
    resources :tw_timelines do
      as_routes
    end
    resources :accounts,:facebook_accounts,:twitter_accounts do
      as_routes
      collection do
       # get 'insights'
        match '/insights/*path' => "accounts#insights", via: [:get]
        get 'start_producers'
        get 'stop_producers'
        get 'start_consumer'
        get 'stop_consumer'
        get 'fetch'
      end
    end
    resources :groups do
      as_routes
    end
    
    resources :subgroups do
      as_routes
    end
    
    resources :regions do
      as_routes
    end
    
    resources :countries do
      as_routes
    end
    resources :sc_segments do
      as_routes
    end
    resources :languages do
      as_routes
    end
    
    resources :accounts_countries do
      as_routes
    end
    resources :accounts_sc_segments do
      as_routes
    end
    resources :accounts_regions do
      as_routes
    end
    resources :accounts_users do
      as_routes
    end
=end    
    resources :users do
      as_routes
      member do
        get 'ed'
      end
      
      collection do
        get 'ls'
      end
    end
  end
  
  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
