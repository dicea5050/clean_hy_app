Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # 管理者認証関連
  get "login", to: "administrators#login", as: "login"
  post "authenticate", to: "administrators#authenticate", as: "authenticate"
  delete "logout", to: "administrators#logout", as: "logout"

  # 管理者マスター
  resources :administrators

  # マスター一覧
  get "masters", to: "masters#index", as: "masters"

  # 各種マスター
  resources :tax_rates
  resources :products
  
  # 顧客関連のルート（個別ルートを先に定義）
  get "customers/search", to: "customers#search"
  get "customers/company_name_search", to: "customers#company_name_search"
  
  resources :customers do
    member do
      get :delivery_locations
    end
  end
  
  resources :payment_methods
  resources :company_informations
  resources :bank_accounts
  resources :units
  resources :product_specifications
  resources :delivery_locations
  resources :product_categories

  # 受注情報（Orders）CRUD機能
  resources :orders do
    collection do
      get :import_csv
      post :process_csv
      get :new_order_item
      get :find_customer_by_code
      get :find_product_by_code
      get :search_customers
      get :search_products
    end

    member do
      get :delivery_slip
    end
  end

  # 請求書発行機能
  resources :invoices do
    collection do
      post :bulk_request_approval
    end
    member do
      get :pdf
      get :receipt
    end
  end

  # ショップ機能用のルート
  namespace :shop do
    resources :products, only: [ :index, :show ]
    resource :cart, only: [ :show, :update, :destroy ]
    resources :orders, only: [ :new, :create ]
    get "orders/complete", to: "orders#complete", as: "order_complete"

    # カスタマーログイン関連
    get "login", to: "sessions#new", as: "login"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy", as: "logout"
  end

  # ショップのルートページを商品一覧に設定
  get "/shop", to: "shop/products#index"

  # ルートパスの設定
  root to: "administrators#login"

  resources :invoice_approvals, only: [ :index ] do
    collection do
      post :bulk_create
    end
    member do
      post :approve
      post :reject
    end
  end
end
