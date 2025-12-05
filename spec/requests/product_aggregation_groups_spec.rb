require 'rails_helper'

RSpec.describe "ProductAggregationGroups", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/product_aggregation_groups/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update_all" do
    it "returns http success" do
      get "/product_aggregation_groups/update_all"
      expect(response).to have_http_status(:success)
    end
  end

end
