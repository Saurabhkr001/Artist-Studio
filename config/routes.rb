Rails.application.routes.draw do
  get "profile/edit"
  devise_for :users

  root to: "home#index"

  resources :artworks, param: :slug do
    resources :studio_notes, only: [ :create, :destroy ],
              shallow: true,
              path: "letters"
    collection do
      get :catalogue
    end
  end

  get "/analytics", to: "home#analytics", as: :analytics

  get "/portfolio", to: "portfolio#index", as: :portfolio
  get "/portfolio/:slug", to: "portfolio#show", as: :portfolio_artwork
  get "/credits", to: "home#credits"
  get "/profile/edit", to: "profile#edit", as: :edit_profile
  patch "/profile",     to: "profile#update", as: :profile
end
