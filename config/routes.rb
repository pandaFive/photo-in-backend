Rails.application.routes.draw do
  namespace "api" do
    resources :accounts, only: [:index, :show, :create, :update, :destroy]
  end
end
