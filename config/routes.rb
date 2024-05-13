Rails.application.routes.draw do
  namespace "api" do
    resources :accounts, only: [:index, :show, :create, :update, :destroy]
    get  "/account",                  to: "accounts#get"
    post "/account/login",            to: "authentications#login"
    get  "/account/tasks",            to: "tasks#get_account_task"
    resources :areas, only: [:index, :show, :create, :update, :destroy]
    resources :account_areas, only: [:create, :destroy]
    resources :tag_accounts, only: [:create, :destroy]
    resources :tags, only: [:index, :show, :create, :update, :destroy]
    resources :tasks, only: [:index, :show, :create, :update, :destroy]
    post   "/tasks/:id/tag",            to: "tasks#add_tag"
    delete "/tasks/:id/tag",            to: "tasks#remove_tag"
    put    "/tasks/:id/completed",      to: "tasks#completed"
    put    "/tasks/:id/ng",             to: "tasks#ng"
    post   "/tasks/newCycle",           to: "tasks#create_new_cycle"
    get    "/unfulfilled-count",        to: "tasks#unfulfilleds_count"
    get    "/completed-data",           to: "tasks#get_complete_data"
    resources :comments, only: [:index, :show, :create, :update, :destroy]
    resources :assigns, only: [:index, :show, :create, :update, :destroy]
    post "tasks/assign/cycle", to: "assigns#cycle_create"
  end
end
