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

    scope module: :procurements, path: "procurements" do
      resources :capital_proposals, path: "capital-proposals" do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
        end
      end

      resources :request_for_purchases, path: "request-for-purchases" do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
          post "process-import-details"
          get "add-rfp-details"
        end
      end

      resources :purchase_orders, path: "purchase-orders" do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
          get "load-rfp-details"
        end
      end

      resources :delivery_orders, path: "delivery-orders" do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
        end
      end
    end

    scope module: :asset_management, path: "asset-management" do
      resources :assets do
        collection do
          delete "destroy-many"
          delete "report-queues-destroy-many"
          post "process-import"
          get "import/download-template", to: "import_download_template", as: "import_download_template"
          get "site-default"
          get "export-confirm"
          post "export"
          get "report-queues"
          get "report-queues/download/:report_id", to: "report_queues_download", as: "report_queues_download"
          get "inventory-locations"

          scope "/import" do
            get "/", to: "import", as: "import"
            get "asset-registrations", to: "import_asset_registrations", as: "import_asset_registrations"
            get "asset-software-registrations", to: "import_asset_software_registrations", as: "import_asset_software_registrations"
            post "asset-software-registrations", to: "process_import_asset_software_registrations", as: "process_import_asset_software_registrations"
            get "download-template-asset-software-registrations", to: "import_download_template_asset_software_registrations", as: "import_download_template_asset_software_registrations"
          end
        end

        member do
          # get "search_user_assets"
          get "location", to: "edit_location"
          patch "location", to: "update_location"

          get "software", to: "edit_software"
          patch "software", to: "update_software"
        end
      end

      resources :user_assets, path: "user-assets" do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
        end

        member do
          get "assets", to: "assets"
        end
      end

      resources :asset_locations, path: "asset-locations" do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
          patch "update-asset-location"
          get "search-asset", to: "search_asset"
        end
      end
    end

    scope module: :inventory_management, path: "inventory-management" do
      resources :inventory_locations, path: "inventory-locations" do
        collection do
          delete "destroy-many"
          post "add-fields"
          get "rooms"
          get "rooms-storage-units"
          get "rooms-storage-units-bins"
        end
      end
    end

    scope module: :settings, path: "settings" do
      resources :site_groups, path: "site-groups" do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
        end
      end

      resources :sites do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
        end
      end

      resources :site_defaults, path: "site-defaults" do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
        end
      end

      resources :asset_item_types, path: "asset-item-types" do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
        end
      end

      resources :asset_models, path: "asset-models" do
        collection do
          delete "destroy-many"
          get "asset-item-types"
          get "import"
          post "process-import"
        end
      end

      resources :components do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
        end
      end
    end

    scope module: :master, path: "master" do
      resources :brands do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
        end
      end

      resources :vendors do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
        end
      end

      resources :departments do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
        end
      end

      resources :site_stats do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
        end
      end

      resources :projects do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
        end
      end

      resources :softwares do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
        end
      end

      resources :component_types do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
        end
      end

      resources :asset_types do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
        end
      end

      resources :asset_schedules do
        collection do
          delete "destroy-many"
        end
      end

      resources :storage_units do
        collection do
          delete "destroy-many"
        end
      end
    end

    scope module: :access_management, path: "access-management" do
      resources :accounts do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
        end
      end

      resources :roles do
        collection do
          delete "destroy-many"
          get "import"
          post "process-import"
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
        post "site-stats-import"
        post "asset-classes-import"
        post "assets-import"
        post "asset-components-import"
        post "asset-softwares-import"
      end
    end
  end
end
