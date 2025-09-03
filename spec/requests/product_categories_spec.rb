require 'rails_helper'

RSpec.describe "ProductCategories", type: :request do
  let(:product_category) { ProductCategory.create!(name: "Test Category", code: "TEST001") }

  before do
    # 認証をスキップ
    allow_any_instance_of(ProductCategoriesController).to receive(:require_login).and_return(true)
  end

  describe "GET /index" do
    it "returns http success" do
      get "/product_categories"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/product_categories/#{product_category.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/product_categories/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/product_categories/#{product_category.id}/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    it "creates a new product category" do
      post "/product_categories", params: { product_category: { name: "New Category", code: "NEW001" } }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /update" do
    it "updates the product category" do
      patch "/product_categories/#{product_category.id}", params: { product_category: { name: "Updated Category" } }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE /destroy" do
    it "destroys the product category" do
      delete "/product_categories/#{product_category.id}"
      expect(response).to have_http_status(:redirect)
    end
  end
end
