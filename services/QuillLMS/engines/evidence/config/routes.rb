# frozen_string_literal: true

Evidence::Engine.routes.draw do
  resources :activities, only: [:index, :show, :create, :update, :destroy] do
    member do
      get :activity_versions
      get :change_logs
      get :invalid_highlights
      put :increment_version
      get :rules
      get :topic_optimal_info
      post :labeled_synthetic_data
      post :seed_data
    end
  end

  resources :automl_models, only: [:index, :show, :create, :update, :destroy] do
    member { put :activate }
    collection { get :deployed_model_names_and_projects }
  end

  put 'automl_models/:prompt_id/enable_more_than_ten_labels' => 'automl_models#enable_more_than_ten_labels'

  resource :feedback, only: [:create], controller: :feedback

  resources :hints, only: [:index, :show, :create, :update, :destroy]
  put 'rules/update_rule_order' => 'rules#update_rule_order'

  resources :rules, only: [:index, :show, :create, :update, :destroy] do
    collection { get :universal }
  end

  resources :turking_round_activity_sessions, only: [:index, :show, :create, :update, :destroy] do
    collection do
      get :validate
    end
  end
  resources :turking_rounds, only: [:index, :show, :create, :update, :destroy]

  resources :activity_healths, only: [:index]

  resources :prompt_healths, only: [:index]

  namespace :research do
    namespace :gen_ai do
      resources :llms, only: [:new, :create, :show, :index]
      resources :llm_prompts, only: [:show]
      resources :llm_prompt_templates, only: [:new, :create, :show, :index, :edit, :update]

      resources :stem_vaults, only: [] do
        resources :guidelines, only: [:new, :create]
        resources :datasets, only: [:new, :create, :show], shallow: true
      end

      resources :datasets, only: [] do
        resources :trials, only: [:new, :create, :show] do
          post :retry, on: :member
        end

        resources :comparisons, only: [:create, :show]
        resources :prompt_examples, only: [:new, :create]
      end

      resources :activities, only: [:new, :create, :show, :index] do
        resources :stem_vaults, only: [:new, :create, :show, :index], shallow: true
      end

      resources :auto_chain_of_thoughts, only: [:new, :create]
      resources :g_evals, only: [:new, :create, :show]
      resources :prompt_template_variables, only: [:new, :create, :show, :index]
    end
  end
end
