AlteredBeast::Application.routes.draw do
  get '/session' => "sessions#create", :as => 'open_id_complete'

  resources :sites, :moderatorships

  resources :forums do
    resources :topics do
      resources :posts
      resource :monitorship
    end
    resources :posts
  end

  resources :posts do
    get :search, :on => :collection
  end
  resources :users do
    member do
      # Accept both PUT (legacy) and PATCH (Rails-4+ form_for default).
      # Rails 8.1 removed the multi-action `match :a, :b, via:` form;
      # each action needs its own line.
      match :suspend,    via: [:put, :patch]
      match :make_admin, via: [:put, :patch]
      match :unsuspend,  via: [:put, :patch]
      get :settings
      delete :purge
    end
    resources :posts, :only => [:index] do
#      get :monitored, :on => :collection, :shallow => true
    end
  end
  get '/users/:user_id/monitored(.:format)' => 'posts#monitored', :as => 'monitored_posts'

  get '/activate(/:activation_code)' => 'users#activate', :as => 'activate'
  get '/signup' => 'users#new', :as => 'signup'
  get '/settings' => 'users#settings', :as => 'settings'
  get '/login' => 'sessions#new', :as => 'login'
  get '/logout' => 'sessions#destroy', :as => 'logout'
  match '/itex' => 'itex#index', via: [:get, :post]
  delete '/monitorship/:forum_id/:topic_id' => 'monitorships#destroy', :as => 'monitorship'
  post '/monitorship/:forum_id/:topic_id'   => 'monitorships#create'

  resource  :session

  root :to => 'forums#index'
end
