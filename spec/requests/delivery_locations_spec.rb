require 'rails_helper'

RSpec.describe "DeliveryLocations", type: :request do
  let(:customer) { Customer.create!(
    customer_code: "TEST001", 
    company_name: "Test Customer", 
    postal_code: "123-4567", 
    address: "Test Address",
    invoice_delivery_method: :electronic
  ) }
  let(:delivery_location) { DeliveryLocation.create!(name: "Test Location", address: "Test Address", customer: customer) }

  describe "GET /index" do
    it "returns http success" do
      get "/delivery_locations"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/delivery_locations/#{delivery_location.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/delivery_locations/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/delivery_locations/#{delivery_location.id}/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    it "creates a new delivery location" do
      post "/delivery_locations", params: { delivery_location: { name: "New Location", address: "New Address", customer_id: customer.id } }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /update" do
    it "updates the delivery location" do
      patch "/delivery_locations/#{delivery_location.id}", params: { delivery_location: { name: "Updated Location" } }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE /destroy" do
    it "destroys the delivery location" do
      delete "/delivery_locations/#{delivery_location.id}"
      expect(response).to have_http_status(:redirect)
    end
  end
end
