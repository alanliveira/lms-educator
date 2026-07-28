Rails.application.routes.draw do
  if defined?(Rswag::Api)
    mount Rswag::Api::Engine => '/api-docs'
  end

  if defined?(Rswag::Ui)
    mount Rswag::Ui::Engine => '/api-docs'
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ('/')
  root 'courses#index'

  resource :setup, only: %i[new create], controller: :setup
  get "wrong_domain", to: "wrong_domains#show"
  post "wrong_domain/contact", to: "wrong_domains#create", as: :wrong_domain_contact
  get "certificates/:verification_code", to: "certificate_validations#show", as: :certificate_validation

  resources :companies do
    member do
      patch :add_course
      delete 'remove_course/:course_id', to: 'companies#remove_course', as: 'remove_course_from'
      patch 'access/:course_id', to: 'companies#toggle_access', as: 'course_access'
    end
  end

  resources :courses do
    resource :certificate, only: %i[edit update], controller: :certificates do
      get :download
    end
    resources :course_classes, except: [:index]
    post "course_classes/:course_class_id/complete", to: "course_classes#complete", as: :complete_course_class
  end

  resources :dashboard, only: [:index]

  resources :users do
    collection do
      resources :histories, only: [:create]
    end
    member do
      get :status
    end
  end

  resources :sessions, only: [:index, :show, :destroy]

  get  'sign_in', to: 'sessions#new'
  post 'sign_in', to: 'sessions#create'
  get  'sign_up', to: 'registrations#new'
  post 'sign_up', to: 'registrations#create'

  resource :password, only: [:edit, :update]

  namespace :identity do
    resource :email,              only: [:edit, :update]
    resource :email_verification, only: [:show, :create]
    resource :password_reset,     only: [:new, :edit, :create, :update]
  end
end
