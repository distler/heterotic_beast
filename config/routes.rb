AlteredBeast::Application.routes.draw do
  get '/session' => "sessions#create", :as => 'open_id_complete'

  resources :sites, :moderatorships, :monitorship

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
      put :suspend, :make_admin, :unsuspend
      get :settings
      delete :purge
    end
    resources :posts, :only => [:index] do
#      get :monitored, :on => :collection, :shallow => true
    end
  end
  match '/users/:user_id/monitored(.:format)' => 'posts#monitored', :as => 'monitored_posts'

  match '/activate/:activation_code' => 'users#activate', :activation_code => nil, :as => 'activate'
  match '/signup' => 'users#new', :as => 'signup'
  match '/settings' => 'users#settings', :as => 'settings'
  match '/login' => 'sessions#new', :as => 'login'
  match '/logout' => 'sessions#destroy', :as => 'logout'
  match '/itex'  => 'itex#index'
  delete '/monitorship/:forum_id/:topic_id' => 'monitorships#destroy', :as => 'monitorship' 
  match '/monitorship/:forum_id/:topic_id' => 'monitorships#create', :as => 'monitorship' 

  resource  :session

  root :to => 'forums#index'
end
