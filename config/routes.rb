Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root to: redirect("/auth/sign-in")

  get "/auth/sign-in", to: "sessions#new"
  post "/auth/sign-in", to: "sessions#create"
  delete "/auth/sign-out", to: "sessions#destroy"

  namespace :admin do
    get "/", to: "home#index"

    scope module: :entries, path: "entries" do
      get "/", to: "entries#index", as: :entries

      resources :brands do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end
      end

      resources :vendors do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end
      end

      resources :departments do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end
      end

      resources :site_stats do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end
      end

      resources :projects do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end
      end

      resources :site_groups do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end
      end

      resources :sites do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end
      end

      resources :softwares do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end
      end

      resources :component_types do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end
      end

      resources :components do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end
      end

      resources :asset_types do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end
      end

      resources :asset_item_types do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end
      end

      resources :asset_models do
        collection do
          delete "destroy_many"
          get "asset_item_types"
          get "import"
          post "process_import"
        end
      end

      resources :user_assets do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end

        member do
          get "assets", to: "assets"
        end
      end

      resources :capital_proposals do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end
      end

      resources :request_for_purchases do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
          post "process_import_details"
          get "add_rfp_details"
        end
      end

      resources :purchase_orders do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
          get :load_rfp_details
        end
      end

      resources :delivery_orders do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end
      end

      resources :site_defaults do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end
      end

      resources :assets do
        collection do
          delete "destroy_many"
          delete "report_queues_destroy_many"
          get "import"
          post "process_import"
          get "import/download_template", to: "import_download_template", as: "import_download_template"
          get "site_default"
          get "export_confirm"
          post "export"
          get "report_queues"
          get "report_queues/download/:report_id", to: "report_queues_download", as: "report_queues_download"
        end

        member do
          # get "search_user_assets"
          get "location", to: "edit_location"
          patch "location", to: "update_location"

          get "software", to: "edit_software"
          patch "software", to: "update_software"
        end
      end

      resources :asset_schedules do
        collection do
          delete "destroy_many"
        end
      end

      resources :storage_units do
        collection do
          delete "destroy_many"
        end
      end

      resources :inventory_locations do
        collection do
          delete "destroy_many"
          post "add_fields"
        end
      end
    end

    scope module: :setups, path: "setups" do
      get "/", to: "setups#index", as: :setups

      resources :accounts do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end
      end

      resources :roles do
        collection do
          delete "destroy_many"
          get "import"
          post "process_import"
        end
      end
    end

    scope module: :charts do
      resources :charts, only: [] do
        collection do
          get "asset-registrations", to: "charts#asset_registrations"
          get "asset-projects", to: "charts#asset_projects"
        end
      end
    end

    resources :importers do
      collection do
        post "site_stats_import"
        post "asset_classes_import"
        post "assets_import"
        post "asset_components_import"
        post "asset_softwares_import"
      end
    end
  end
end
