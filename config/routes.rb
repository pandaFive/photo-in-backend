Rails.application.routes.draw do
  namespace "api" do
    resources :accounts, only: [:index, :show, :create, :update, :destroy]
    resources :areas, only: [:index, :show, :create, :update, :destroy]
    resources :account_areas, only: [:create, :destroy]
    resources :tag_accounts, only: [:create, :destroy]
    resources :tags, only: [:index, :show, :create, :update, :destroy]
    resources :tasks, only: [:index, :show, :create, :update, :destroy]
    post "/tasks/tag",       to: "tasks#add_tag"
    post "/tasks/completed", to: "tasks#completed"
    resources :comments, only: [:index, :show, :create, :update, :destroy]
    resources :assigns, only: [:index, :show, :create, :update, :destroy]
    post "tasks/assign/cycle", to: "assigns#cycle_create"
  end
end
