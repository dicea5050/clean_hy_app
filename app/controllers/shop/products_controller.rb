class Shop::ProductsController < ApplicationController
  layout 'shop'
  
  def index
    @products = Product.available.order(created_at: :desc)
  end
  
  def show
    @product = Product.find(params[:id])
  end
end 