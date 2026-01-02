require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  resources :models do
    collection { delete :destroy_all }
  end
  resources :post_subjects do
    collection { delete :destroy_all }
  end
  resources :sources do
    collection { delete :destroy_all }
  end
  resources :posts do
    member do
      post :index_post
      post :analyze_sentiment
    end
    collection { delete :destroy_all }
  end
  resources :channels do
    collection { delete :destroy_all }
  end
  get "test/index"
  get "test/neo4j"
  get "home/index"
  get "home/test"
  devise_for :users

  authenticate :user, lambda { |u| u.super_admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  authenticate :user do
    root "dashboard#show", as: :authenticated_root
  end
  
  root "dashboard#show"
  get "status", to: "dashboard#status"

  resources :customers do
    collection { delete :destroy_all }
  end

  resources :users do
    collection { delete :destroy_all }
  end

  resources :projects do
    resources :subjects, shallow: true
    member do
      post :analyze_all_sentiment
    end
    collection { delete :destroy_all }
  end

  resources :subjects do
    member do
      post :instant_feed
    end
    collection { delete :destroy_all }
  end

  resources :feeders do
    member do
      post :run_now
      post :reprocess
    end
    collection { delete :destroy_all }
  end

  resources :results, only: %i[index show destroy] do
    collection { delete :destroy_all }
    member do
      get :upsert, to: "results#upsert"
    end
  end
  get "graph", to: "graph#show"
  post "graph/reprocess", to: "graph#reprocess", as: :reprocess_graph
  get "llm", to: "llm#index"
  post "llm", to: "llm#create"
  post "llm/stream", to: "llm#stream", as: :llm_stream
  post "llm/search", to: "llm#search", as: :llm_search
  delete "llm", to: "llm#clear"

  namespace :api do
    namespace :v1 do
      get "graph", to: "graph#index"
      get "analytics/top_hashtags", to: "analytics#top_hashtags"
      get "analytics/top_users", to: "analytics#top_users"
      post "sentiment", to: "sentiment#create"
      post "notebook/query", to: "notebook#query"
    end
  end
end
