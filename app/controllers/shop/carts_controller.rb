class Shop::CartsController < ApplicationController
  layout 'shop'
  
  def show
    @cart = current_cart
  end
  
  def update
    @cart = current_cart
    
    # 単一商品の場合
    if params[:product_id].present?
      product = Product.find(params[:product_id])
      quantity = params[:quantity].to_i
      
      if quantity > 0
        @cart.add_item(product, quantity)
      end
    # 複数商品の一括追加の場合
    elsif params[:product_quantities].present?
      params[:product_quantities].each do |product_id, quantity|
        quantity = quantity.to_i
        if quantity > 0
          product = Product.find(product_id)
          @cart.add_item(product, quantity)
        end
      end
    end
    
    session[:cart] = @cart.serialize
    
    redirect_to shop_cart_path, notice: '商品をカートに追加しました'
  end
  
  def destroy
    session[:cart] = nil
    redirect_to shop_products_path, notice: 'カートを空にしました'
  end
  
  private
  
  def current_cart
    Cart.from_hash(session[:cart] || {})
  end
end 